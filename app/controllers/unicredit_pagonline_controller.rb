# encoding: utf-8 
class UnicreditPagonlineController < Spree::BaseController
  ssl_required
  
  def show
    if params[:payment_method_id] and PaymentMethod.exists? params[:payment_method_id]
      @payment_method = PaymentMethod.find params[:payment_method_id]
    else
      flash[:error] = "ERRORE, parametro payment_method_id errato, il metodo di pagamento con id=#{params[:payment_method_id]} non esiste !"
      redirect_to checkout_state_url(:payment)
    end           
               
    # Preferred data
    numeroCommerciante =  @payment_method.preferred_numero_commerciante
    stabilimento = @payment_method.preferred_stabilimento
    userID = @payment_method.preferred_user_id
    password = @payment_method.preferred_password  
    valuta = @payment_method.preferred_valuta
    flagRiciclaOrdine = @payment_method.preferred_flag_ricicla_ordine ? 'Y' : 'N'
    flagDeposito = @payment_method.preferred_flag_deposito ? 'Y' : 'N' 
    tipoRispostaApv = @payment_method.preferred_tipo_risposta_apv
    urlOk = @payment_method.preferred_url_ok
    urlKo = @payment_method.preferred_url_ko
    stringaSegreta = @payment_method.preferred_stringa_segreta 
    
    # Order data
    if params[:order_id] and Order.exists? params[:order_id]
      @order = Order.find params[:order_id]
    else
      flash[:error] = "ERRORE, parametro order_id errato, l'ordine id=#{params[:order_id]} non esiste !"
      redirect_to checkout_state_url(:payment)
    end      
    numeroOrdine = @order.number
    totaleOrdine = (@order.total*100).to_i.to_s
    
    # Compute input string 
    inputMac  = "numeroCommerciante=#{numeroCommerciante.strip}"
    inputMac << "&stabilimento=#{stabilimento.strip}"
    inputMac << "&userID=#{userID.strip}"
    inputMac << "&password=#{password.strip}"
    inputMac << "&numeroOrdine=#{numeroOrdine.strip}"
    inputMac << "&totaleOrdine=#{totaleOrdine.strip}"
    inputMac << "&valuta=#{valuta.strip}"
    inputMac << "&flagRiciclaOrdine=#{flagRiciclaOrdine.strip}"
    inputMac << "&flagDeposito=#{flagDeposito.strip}"
    inputMac << "&tipoRispostaApv=#{tipoRispostaApv.strip}"
    inputMac << "&urlOk=#{urlOk.strip}"
    inputMac << "&urlKo=#{urlKo.strip}"
    inputMac << "&#{stringaSegreta.strip}" # NB. the stringaSegreta ! 
    # qui potrei aggiungere gli eventuali parametri facoltativi :
    # 'tipoPagamento' e 'causalePagamento'
    
    # Compute MAC code
    mac = mac_code(inputMac)
    
    # Compute the url  
    inputUrl = "https://pagamenti.unicredito.it/initInsert.do?numeroCommerciante=#{numeroCommerciante.strip}"
    inputUrl << "&stabilimento=#{stabilimento.strip}"
    inputUrl << "&userID=#{userID.strip}"
    inputUrl << "&password=Password";      #la password vera viene usata solo per il calcolo del MAC e non viene inviata al sito dei pagamenti (qui è sostituita con il valore fittizio "Password")
    inputUrl << "&numeroOrdine=#{numeroOrdine.strip}"
    inputUrl << "&totaleOrdine=#{totaleOrdine.strip}"
    inputUrl << "&valuta=#{valuta.strip}"
    inputUrl << "&flagRiciclaOrdine=#{flagRiciclaOrdine.strip}"
    inputUrl << "&flagDeposito=#{flagDeposito.strip}"
    inputUrl << "&tipoRispostaApv=#{tipoRispostaApv.strip}"
    inputUrl << "&urlOk=#{CGI.escape urlOk.strip}"
    inputUrl << "&urlKo=#{CGI.escape urlKo.strip}"
    inputUrl << "&mac=#{CGI.escape mac}"
    
    @form_url = inputUrl  
    
  end
      
  def result_ko  
    # load order and payment method  
    begin
      @order = Order.find_by_number(params[:numeroOrdine])
      @payment_method = @order.payment_method
      stringaSegreta = @payment_method.preferred_stringa_segreta       
    rescue
      flash[:error] = "ERRORE nei parametri ricevuti da PagOnline: #{params.inspect}"
      redirect_to checkout_state_url(:payment)  
    end      
    # make string for MAC code
    inputMac  = "numeroOrdine=#{params[:numeroOrdine]}" 
    inputMac << "&numeroCommerciante=#{params[:numeroCommerciante]}" 
    inputMac << "&stabilimento=#{params[:stabilimento]}" 
    inputMac << "&esito=#{params[:esito]}"               
    inputMac << "&#{stringaSegreta.to_s.strip}"
  	# Compute MAC code
    mac = mac_code(inputMac)
  	# test the MAC param
  	if mac == params[:mac]
      flash[:error] = "Esito transazione con Unicredito PagOnline negativo."
      redirect_to checkout_state_url(:payment)    
    else
      flash[:error] = "Mac code non corretto. Operazione annullata."
      redirect_to checkout_state_url(:payment)
    end   
  end  
  
  def result_ok          
    logger.info "UnicreditPagonlineController#result_ok:params: #{params.inspect}"   
    # load order and payment method  
    begin
      @order = Order.find_by_number(params[:numeroOrdine])
      @payment_method = @order.payment_method
      stringaSegreta = @payment_method.preferred_stringa_segreta       
      # set order state = processing
      @order.payment.started_processing      
    rescue
      flash[:error] = "ERRORE nei parametri ricevuti da PagOnline: #{params.inspect}"
      logger.info "UnicreditPagonlineController#result_ok : ERRORE caricando i dati: #{@order} #{@payment_method} #{stringaSegreta}"
      redirect_to checkout_state_url(:payment)  
      return
    end
    # make string for MAC code
    inputMac  = "numeroOrdine=#{params[:numeroOrdine]}" 
    inputMac << "&numeroCommerciante=#{params[:numeroCommerciante]}" 
    inputMac << "&stabilimento=#{params[:stabilimento]}" 
    inputMac << "&esito=#{params[:esito]}" 
  	inputMac << "&dataApprovazione=#{params[:dataApprovazione]}"  	
    inputMac << "&#{stringaSegreta.to_s.strip}"
  	# Compute MAC code
    mac = mac_code(inputMac)
  	# test the MAC param
  	if mac == params[:mac]                                              
      @order.payment.complete
      @order.next
      @order.save
      session[:order_id] = nil
      logger.info "UnicreditPagonlineController#result_ok : tutto OK, ordine completato, #{@order.inspect}"
      redirect_to order_url(@order, {:checkout_complete => true, :order_token => @order.token}), :notice => I18n.t("unicredit_pagonline_payment_success")  
    else                                    
      @order.payment.fail
      logger.info "UnicreditPagonlineController#result_ok : ERRORE, mac errato, calcolato=#{mac} param=#{params[:mac]}"
      flash[:error] = "Mac code non corretto. Operazione annullata."
      redirect_to checkout_state_url(:payment)
    end
  end
  
  def eventlistener    
    @msg = "UnicreditPagonlineController#eventlistener" 
    # load order and payment method  
    logger.info "UnicreditPagonlineController#eventlistener ha ricevuto questi parametri: #{params.inspect} "
    begin
      @order = Order.find_by_number(params[:numeroOrdine])
      @payment_method = @order.payment_method
      stringaSegreta = @payment_method.preferred_stringa_segreta       
    rescue  
      logger.info = "ERRORE nei parametri ricevuti da UnicreditPagonlineController#eventlistener: #{params.inspect}"
      @msg = "ERRORE nei parametri ricevuti da UnicreditPagonlineController#eventlistener: #{params.inspect}" 
    end  
    return unless @order
    # make string for MAC code
    inputMac = request.fullpath.gsub(/^.*eventlistener\?/,'').gsub(/&mac=.*$/, '') 
    inputMac << "&#{stringaSegreta.to_s.strip}" 
  	# Compute MAC code
    mac = mac_code(inputMac) 
       debugger
  	# test the MAC param
  	if mac == params[:mac]
      # mac ok 
      if params[:tipomessaggio] == "PAYMENT_STATE" and params[:statoattuale]
        # messaggio relativo allo stato del pagamento  
        case params[:statoattuale]
        when 'OK' 
          unless @order.payment.completed?
            @order.payment.started_processing
            @order.payment.complete    
            logger.info "UnicreditPagonlineController#eventlistener : Pagamento confermato e completato" 
            @msg = "UnicreditPagonlineController#eventlistener : Pagamento confermato e completato"
          end
          unless @order.completed?
            @order.state = "complete"
            @order.save
            @order.finalize! 
            logger.info "UnicreditPagonlineController#eventlistener : Ordine completato" 
            @msg = "UnicreditPagonlineController#eventlistener : Ordine completato"
          end  
        when 'IC'  
          unless @order.payment.completed?
            @order.payment.started_processing
            @order.payment.complete   
            logger.info "UnicreditPagonlineController#eventlistener : Pagamento confermato e completato" 
            @msg = "UnicreditPagonlineController#eventlistener : Pagamento confermato e completato"
          end
          unless @order.completed?
            @order.state = "complete"
            @order.save
            @order.finalize! 
            logger.info "UnicreditPagonlineController#eventlistener : Ordine completato" 
            @msg = "UnicreditPagonlineController#eventlistener : Ordine completato"
          end
        when 'KO'   
          unless @order.payment.failed?
            @order.payment.started_processing
            @order.payment.fail   
            logger.info "UnicreditPagonlineController#eventlistener : Pagamento fallito" 
            @msg = "UnicreditPagonlineController#eventlistener : Pagamento fallito"
          end 
          if @order.completed?
            @order.state = "payment"
            @order.save   
            logger.info "UnicreditPagonlineController#eventlistener : Ordine NON completo perchè il pagamento è fallito" 
            @msg = "UnicreditPagonlineController#eventlistener : Ordine NON completo perchè il pagamento è fallito"
          end
        else
          # valore sconosciuto
          @msg = "UnicreditPagonlineController#eventlistener : valore sconosciuto"           
        end
      else
        # messaggio sconosciuto 
        @msg = "UnicreditPagonlineController#eventlistener : messaggio sconosciuto"
      end
    else
      # mac errato 
      logger.info "UnicreditPagonlineController#eventlistener : ERRORE, mac errato, calcolato=#{mac} param=#{params[:mac]}" 
      @msg = "UnicreditPagonlineController#eventlistener : ERRORE, mac errato, calcolato=#{mac} param=#{params[:mac]}"
    end    
    render :text => @msg
  end
  
  
  
  private 
  
  def mac_code(string)
    return  Digest::MD5.base64digest(string)
  end
  
end