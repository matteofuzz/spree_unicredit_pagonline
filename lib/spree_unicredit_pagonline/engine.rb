module Spree::UnicreditPagonline; end
module SpreeUnicreditPagonline
  class Engine < Rails::Engine    
    engine_name 'spree_unicredit_pagonline'

    config.autoload_paths += %W(#{config.root}/lib)
    
    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end 
    
    initializer "spree.unicredit_pagonline.preferences", :before => :load_config_initializers do |app|
      Spree::UnicreditPagonline::Config = Spree::UnicreditPagonlineConfiguration.new
    end
    
    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end 
        
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/overrides/*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
      
      #require 'active_merchant'
      # register of Unicredit Pagonline 
      #BillingIntegration::UnicreditPagonline.register
      # config.after_initialize do |app|
      #         app.config.spree.payment_methods += [ BillingIntegration::UnicreditPagonline ]
      #       end

    end
    
    initializer "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods += [ Spree::BillingIntegration::UnicreditPagonline ]
    end

    config.to_prepare &method(:activate).to_proc
  end
end