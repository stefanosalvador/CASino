
class CASino::User < CASino::ApplicationRecord
  serialize :extra_attributes, Hash

  has_many :ticket_granting_tickets, dependent: :destroy
  has_many :two_factor_authenticators, dependent: :destroy
  has_many :login_attempts, dependent: :destroy

  scope :locked, -> { where('locked_until > ?', Time.now) }

  def active_two_factor_authenticator
    self.two_factor_authenticators.where(active: true).first
  end

  def locked?
    return false unless locked_until
    locked_until.future?
  end

  def max_failed_logins_reached?(max)
    return false if max.to_i <= 0
    login_attempts.last(max).count(&:failed?) == max
  end
end
