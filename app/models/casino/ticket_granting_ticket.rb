require 'user_agent'

class CASino::TicketGrantingTicket < CASino::ApplicationRecord
  include CASino::ModelConcern::Ticket
  include CASino::ModelConcern::BrowserInfo

  self.ticket_prefix = 'TGC'.freeze

  property :user_agent, String
  property :awaiting_two_factor_authentication, TrueClass, default: false
  property :long_term,  TrueClass, default: false
  property :user_ip,    String

  belongs_to :user, class_name: 'CASino::User'

  design do
    view :by_user_id
    view :by_awaiting_two_factor_authentication
    view :by_user_id_and_awaiting_two_factor_authentication
    view :by_created_at
    view :by_user_id_and_created_at
  end

  # has_many implementation
  def service_tickets
    CASino::ServiceTicket.by_ticket_granting_ticket_id.key(id)
  end
  # dependent: :destroy implementation
  after_destroy do |tgt|
    tgt.service_tickets.each {|st| st.destroy}
  end

  def self.active
    self.by_awaiting_two_factor_authentication.key(false).all.sort_by {|t| t.updated_at}.reverse!
  end

  def self.active_by_user(user)
    self.by_user_id_and_awaiting_two_factor_authentication.key([user.id, false]).all.sort_by {|t| t.updated_at}.reverse!
  end

  def self.cleanup(user = nil)
    self.by_created_at.endkey(CASino.config.two_factor_authenticator[:timeout].seconds.ago).each do |tgt|
      tgt.destroy if(tgt.awaiting_two_factor_authentication == true && (user.nil? || user.id == tgt.user_id))
    end
    self.by_created_at.endkey(CASino.config.ticket_granting_ticket[:lifetime].seconds.ago).each do |tgt|
      tgt.destroy if(tgt.long_term == false && (user.nil? || user.id == tgt.user_id))
    end
    self.by_created_at.endkey(CASino.config.ticket_granting_ticket[:lifetime_long_term].seconds.ago).each do |tgt|
      tgt.destroy if(user.nil? || user.id == tgt.user_id)
    end
  end

  def same_user?(other_ticket)
    if other_ticket.nil?
      false
    else
      other_ticket.user_id == self.user_id
    end
  end

  def expired?
    if awaiting_two_factor_authentication?
      lifetime = CASino.config.two_factor_authenticator[:timeout]
    elsif long_term?
      lifetime = CASino.config.ticket_granting_ticket[:lifetime_long_term]
    else
      lifetime = CASino.config.ticket_granting_ticket[:lifetime]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end
end
