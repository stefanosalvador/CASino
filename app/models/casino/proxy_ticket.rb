require 'addressable/uri'

class CASino::ProxyTicket < CASino::ApplicationRecord
  include CASino::ModelConcern::Ticket

  self.ticket_prefix = 'PT'.freeze

  property :service,  String
  property :consumed, TrueClass, default: false
  
  belongs_to :proxy_granting_ticket, class_name: 'CASino::ProxyGrantingTicket'

  design do
    view :by_proxy_granting_ticket_id
    view :by_created_at_and_consumed
  end

  # has_many polymorphic implementation
  def proxy_granting_tickets
    CASino::ProxyGrantingTicket.by_granter_id_and_granter_type.key([id, self.class.name])
  end
  # dependent: :destroy implementation
  after_destroy do |st|
    st.proxy_granting_tickets.each {|t| t.destroy}
  end

  def self.cleanup_unconsumed
    self.by_created_at_and_consumed.startkey(["", false]).endkey([CASino.config.proxy_ticket[:lifetime_unconsumed].seconds.ago, false]).each {|pt| puts "destroy #{pt.ticket}"; pt.destroy}
  end

  def self.cleanup_consumed
    self.by_created_at_and_consumed.startkey(["", true]).endkey([CASino.config.proxy_ticket[:lifetime_consumed].seconds.ago, true]).each {|pt| pt.destroy}
  end

  def expired?
    lifetime = if consumed?
      CASino.config.proxy_ticket[:lifetime_consumed]
    else
      CASino.config.proxy_ticket[:lifetime_unconsumed]
    end
    (Time.now - (created_at || Time.now)) > lifetime
  end
end
