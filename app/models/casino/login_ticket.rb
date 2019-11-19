class CASino::LoginTicket < CASino::ApplicationRecord
  include CASino::ModelConcern::Ticket
  include CASino::ModelConcern::ConsumableTicket

  self.ticket_prefix = 'LT'.freeze

  def self.cleanup
    by_created_at.endkey(CASino.config.login_ticket[:lifetime].seconds.ago).each { |tk| tk.destroy }
  end

  def expired?
    (Time.now - (created_at || Time.now)) > CASino.config.login_ticket[:lifetime].seconds
  end
end
