class CASino::User < CASino::ApplicationRecord

  property :authenticator,    String
  property :username,         String
  property :extra_attributes, Hash
  property :locked_until,     DateTime
  rw_timestamps!

  design do
    view :by_username
    view :by_username_and_authenticator
    view :by_locked_until
  end

  # has_many implementation
  def ticket_granting_tickets
    CASino::TicketGrantingTicket.by_user_id.key(id)
  end
  def two_factor_authenticators
    CASino::TwoFactorAuthenticator.by_user_id.key(id)
  end
  def login_attempts
    CASino::LoginAttempt.by_user_id.key(id)
  end
  # dependent: :destroy implementation
  after_destroy do |user|
    user.ticket_granting_tickets.each {|t| t.destroy}
    user.two_factor_authenticators.each {|t| t.destroy}
    user.login_attempts.each {|t| t.destroy}
  end

  def self.locked
    self.by_locked_until.startkey(Time.now).endkey({})
  end

  def active_two_factor_authenticator
    CASino::TwoFactorAuthenticator.by_user_id_and_active.key([id, true]).first
  end

  def locked?
    return false unless locked_until
    locked_until.future?
  end

  def max_failed_logins_reached?(max)
    return false if max.to_i <= 0
    CASino::LoginAttempt.by_user_id_and_created_at(descending: true).startkey([id, Time.now]).endkey([id, ""]).limit(max).all.count(&:failed?) == max
  end
end
