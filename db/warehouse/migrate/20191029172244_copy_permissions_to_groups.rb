class CopyPermissionsToGroups < ActiveRecord::Migration
  def up
    Rake::Task["group:create_groups"].invoke
    Rake::Task["group:copy_user_viewables"].invoke
  end
end
