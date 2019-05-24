class AddUserIpToTicketGrantingTicket < ActiveRecord::Migration[5.2]
  def up
    add_column :casino_ticket_granting_tickets, :user_ip, :string
  end

  def down
    remove_column :casino_ticket_granting_tickets, :user_ip
  end
end
