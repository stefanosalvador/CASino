class CASino::ApplicationRecord < CouchRest::Model::Base
  def self.rw_timestamps!
    property(:updated_at, Time, :auto_validation => false)
    property(:created_at, Time, :auto_validation => false)

    set_callback :save, :before do |object|
      object.updated_at = Time.now if object.updated_at.nil?
      object.created_at = Time.now if object.created_at.nil? && object.new?
    end
  end

  def touch
    self.updated_at = Time.now
    self.save
  end

  def update_attribute(key, value)
    self.update_attributes(key => value)
  end
end
