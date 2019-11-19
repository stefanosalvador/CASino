class CASino::AuthTokenTicket < CASino::ApplicationRecord
  include CASino::ModelConcern::Ticket
  include CASino::ModelConcern::ConsumableTicket

  self.ticket_prefix = 'ATT'.freeze

  def self.cleanup
    by_created_at.endkey(CASino.config.auth_token_ticket[:lifetime].seconds.ago).each { |tk| tk.destroy }
  end

  def expired?
    (Time.now - (created_at || Time.now)) > CASino.config.auth_token_ticket[:lifetime].seconds
  end
end
