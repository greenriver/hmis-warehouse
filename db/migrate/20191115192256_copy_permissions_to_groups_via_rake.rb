class CopyPermissionsToGroupsViaRake < ActiveRecord::Migration
  def up
    # Moved to warehouse migrations so that it happens after all tables are available.
    # system("RAILS_ENV=#{Rails.env} bundle exec rake group:create_groups")
    # system("RAILS_ENV=#{Rails.env} bundle exec rake group:copy_user_viewables")
  end
end
