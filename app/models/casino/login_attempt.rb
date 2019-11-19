class CASino::LoginAttempt < CASino::ApplicationRecord
  include CASino::ModelConcern::BrowserInfo

  property :successful, TrueClass, defalt: false
  property :user_ip,    String
  property :user_agent, String
  property :service,    String
  rw_timestamps!

  belongs_to :user, class_name: 'CASino::User'
  
  design do
    view :by_user_id
    view :by_user_id_and_created_at
  end

  def failed?
    !successful?
  end
end
