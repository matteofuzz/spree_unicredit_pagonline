require 'spree_core'
require 'spree_unicredit_pagonline_hooks'  
require 'digest/md5' 
require 'base64'

module SpreeUnicreditPagonline
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      
      require 'active_merchant'
      # register of Unicredit Pagonline 
      BillingIntegration::UnicreditPagonline.register

    end

    config.to_prepare &method(:activate).to_proc
  end
end
