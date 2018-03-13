require 'terminal-table'

namespace :casino do
  namespace :user do
    desc 'Search users by name.'
    task :search, [:query] => :environment do |_task, args|
      users = CASino::User.where('username LIKE ?', "%#{args[:query]}%")
      if users.any?
        headers = [
          'User ID',
          'Username',
          'Authenticator',
          'Two-factor authentication enabled?',
          'Lock active?',
          'Locked until',
        ]
        table = Terminal::Table.new(headings: headers) do |t|
          users.each do |user|
            two_factor_enabled = user.active_two_factor_authenticator ? 'yes' : 'no'
            user_locked = if user.locked_until.nil?
                            'no'
                          else
                            user.locked_until.future? ? 'yes' : 'no'
                          end
            t.add_row [
              user.id,
              user.username,
              user.authenticator,
              two_factor_enabled,
              user_locked,
              user.locked_until,
            ]
          end
        end
        puts table
      else
        puts "No users found matching your query \"#{args[:query]}\"."
      end
    end

    desc 'Deactivate two-factor authentication for a user.'
    task :deactivate_two_factor_authentication, [:user_id] => :environment do |_task, args|
      user = CASino::User.find args[:user_id]
      if user.active_two_factor_authenticator
        user.active_two_factor_authenticator.destroy
        puts "Successfully deactivated two-factor authentication for user ##{args[:user_id]}."
      else
        puts "No two-factor authenticator found for user ##{args[:user_id]}."
      end
    end

    desc 'Re-enable locked user.'
    task :reenable_locked_user, [:user_id] => :environment do |_task, args|
      user = CASino::User.find args[:user_id]
      if user.locked_until.nil? || user.locked_until.past?
        puts "The given user ##{args[:user_id]} is not locked."
      else
        user.update(locked_until: nil)
        puts "The given user ##{args[:user_id]} was successfully unlocked."
      end
    end
  end
end
