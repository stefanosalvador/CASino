class CASino::TwoFactorAuthenticator < CASino::ApplicationRecord

  property :secret,  String
  property :active,  TrueClass, default: false
  property :user_id, String
  rw_timestamps!

  belongs_to :user, class_name: 'CASino::User'

  design do
    view :by_active
    view :by_user_id
    view :by_user_id_and_active
    view :by_created_at_and_active
  end

  def active?
    return active == true
  end

  def self.active
    self.by_active.key(true)
  end

  def self.cleanup
    self.by_active.key(false).each {|tfa| tfa.destroy if(tfa.created_at < lifetime.ago)}
  end

  def self.lifetime
    CASino.config.two_factor_authenticator[:lifetime_inactive].seconds
  end

  def expired?
    !active && (Time.now - (created_at || Time.now)) > self.class.lifetime
  end
end
