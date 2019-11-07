class AddLockedUntilToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :casino_users, :locked_until, :datetime
  end
end
