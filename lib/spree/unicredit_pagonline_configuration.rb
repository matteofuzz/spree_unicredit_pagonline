class Spree::UnicreditPagonlineConfiguration < Spree::Preferences::Configuration
  preference :numero_commerciante, :string, :default => 9999888
  preference :stabilimento, :string, :default => 99988
  preference :user_id, :string, :default => 9999888
  preference :password, :string, :default => 9999888  
  preference :valuta, :string, :default => "978"
  preference :flag_ricicla_ordine, :boolean, :default => false  
  preference :flag_deposito, :boolean, :default => true  
  preference :tipo_risposta_apv, :string, :default => "click"
  preference :url_ok, :string
  preference :url_ko, :string
  preference :stringa_segreta, :string, :default => "b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1"
end