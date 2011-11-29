# 

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module UnicreditPagonline
        autoload :Return, File.dirname(__FILE__) + '/unicredit_pagonline/return.rb'
        autoload :Common, File.dirname(__FILE__) + '/unicredit_pagonline/common.rb'
        autoload :Helper, File.dirname(__FILE__) + '/unicredit_pagonline/helper.rb'
        autoload :Notification, File.dirname(__FILE__) + '/unicredit_pagonline/notification.rb'
       
        #mattr_accessor :service_url
        self.service_url = 'https://pagamenti.unicredito.it'

        def self.notification(post, options = {})
          Notification.new(post)
        end  
        
        def self.return(query_string, options = {})
          Return.new(query_string)
        end
      end
    end
  end
end
