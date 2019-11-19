class CASino::ServiceRule < CASino::ApplicationRecord

  property :enabled, TrueClass, default: true
  property :order,   Integer, default: 10
  property :name,    String
  property :url,     String
  property :regex,   TrueClass, default: false
  timestamps!

  validates_uniqueness_of :url
  validates :name, presence: true
  validates :url, presence: true

  design do
    view :by_enabled
    view :by_name
    view :by_url
  end

  def self.allowed?(service_url)
    rules = self.by_enabled.key(true)
    if rules.empty? && !CASino.config.require_service_rules
      true
    else
      rules.any? { |rule| rule.allows?(service_url) }
    end
  end

  def allows?(service_url)
    if self.regex?
      regex = Regexp.new self.url, true
      if regex =~ service_url
        return true
      end
    elsif self.url == service_url
      return true
    end
    false
  end
end
