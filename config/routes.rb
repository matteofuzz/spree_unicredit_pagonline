Rails.application.routes.draw do
  # Event listener
  match '/unicredit_pagonline/eventlistener' => 'unicredit_pagonline#eventlistener', :as => :unicredit_pagonline_eventlistener
  match '/unicredit_pagonline/show/:order_id/:payment_method_id' => 'unicredit_pagonline#show', :as => :unicredit_pagonline_show           
  match '/unicredit_pagonline/ok' => 'unicredit_pagonline#result_ok', :as => :unicredit_pagonline_ok 
  match '/unicredit_pagonline/ko' => 'unicredit_pagonline#result_ko', :as => :unicredit_pagonline_ko
  #match '/gestpay/comeback' => 'gestpay#comeback', :as => :gestpay_comeback
  #match '/gestpay/comeback_s2s(/:server)' => 'gestpay#comeback_s2s', :as => :gestpay_comeback_s2s
end
