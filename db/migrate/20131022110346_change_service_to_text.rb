class ChangeServiceToText < ActiveRecord::Migration[5.2]
  def change
    change_column :casino_proxy_tickets, :service, :text
    change_column :casino_service_tickets, :service, :text
  end
end
