CheckoutController.class_eval do

  before_filter :redirect_for_unicredit_pagonline, :only => :update

  private

  def redirect_for_unicredit_pagonline
    return unless params[:state] == "payment"
    @payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
    if @payment_method && @payment_method.kind_of?(PaymentMethod::BillingIntegration::UnicreditPagonline)
      @order.update_attributes(object_params)
      redirect_to unicredit_pagonline_show_path(:order_id => @order.id, :payment_method_id => @payment_method.id)
    end
  end
 
end
