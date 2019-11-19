class CopyPermissionsToGroupsViaRake < ActiveRecord::Migration[4.2]
  def up
    system("RAILS_ENV=#{Rails.env} bundle exec rake group:create_groups")
    system("RAILS_ENV=#{Rails.env} bundle exec rake group:copy_user_viewables")
  end
end
