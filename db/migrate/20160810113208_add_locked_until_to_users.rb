class AddLockedUntilToUsers < ActiveRecord::Migration
  def change
    add_column :casino_users, :locked_until, :datetime
  end
end
