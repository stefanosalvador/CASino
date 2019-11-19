require 'addressable/uri'

class CASino::ServiceTicket < CASino::ApplicationRecord
  include CASino::ModelConcern::Ticket

  self.ticket_prefix = 'ST'.freeze

  property :normalized_encoded_service,  String
  property :consumed, TrueClass, default: false
  property :issued_from_credentials, TrueClass, :default => false

  belongs_to :ticket_granting_ticket, class_name: 'CASino::TicketGrantingTicket'
  before_destroy :send_single_sign_out_notification, if: :consumed?

  design do
    view :by_consumed
    view :by_created_at_and_consumed
    view :by_ticket_granting_ticket_id
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
    self.by_created_at_and_consumed.startkey(["", false]).endkey([CASino.config.service_ticket[:lifetime_unconsumed].seconds.ago, false]).each {|st| st.destroy}
  end

  def self.cleanup_consumed
    self.by_consumed.key(true).each do |st|
      st.destroy if(st.created_at < CASino.config.service_ticket[:lifetime_consumed].seconds.ago || st.ticket_granting_ticket_id.nil?)
    end
  end

  def self.cleanup_consumed_hard
    self.by_created_at_and_consumed.startkey(["", true]).endkey([(CASino.config.service_ticket[:lifetime_consumed] * 2).seconds.ago, true]).each {|st| st.destroy}
  end

  def service=(service)
    self.normalized_encoded_service = Addressable::URI.parse(service).normalize.to_str
  end

  def service
    return self.normalized_encoded_service
  end

  def service_with_ticket_url
    service_uri = Addressable::URI.parse(service)
    service_uri.query_values = (service_uri.query_values(Array) || []) << ['ticket', ticket]
    service_uri.to_s
  end

  def expired?
    lifetime = if consumed?
                 CASino.config.service_ticket[:lifetime_consumed]
               else
                 CASino.config.service_ticket[:lifetime_unconsumed]
               end
    (Time.now - (created_at || Time.now)) > lifetime
  end

  private

  def send_single_sign_out_notification
    notifier = SingleSignOutNotifier.new(self)
    notifier.notify
    true
  end
end
