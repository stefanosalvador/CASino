class CASino::ProxyGrantingTicket < CASino::ApplicationRecord
  include CASino::ModelConcern::Ticket

  self.ticket_prefix = 'PGT'.freeze

  before_validation :ensure_iou_present

  property :iou,          String
  property :pgt_url,      String
  property :granter_id,   String
  property :granter_type, String

  validates_uniqueness_of :iou

  design do
    view :by_granter_id_and_granter_type
  end

  # belongs_to polymorphic implementation
  def granter
    granter_type.constantize.find(granter_id)
  end
  def granter=(granter)
    self.granter_id = granter.id
    self.granter_type = granter.class
    self.save
  end

  # has_many implementation
  def proxy_tickets
    CASino::ProxyTicket.by_proxy_granting_ticket_id.key(id)
  end
  # dependent: :destroy implementation
  after_destroy do |pgt|
    pgt.proxy_tickets.each {|pt| pt.destroy}
  end

  private
  def ensure_iou_present
    self.iou ||= create_random_ticket_string('PGTIOU')
  end
end
