class ChangeUserAgentToText < ActiveRecord::Migration[5.2]
  def change
    change_column :casino_ticket_granting_tickets, :user_agent, :text
  end
end
