class CopyPermissionsToGroups < ActiveRecord::Migration
  # Note, this appears to be unable to be run within the migration framework
  # def up
  #   Rake::Task["group:create_groups"].invoke
  #   Rake::Task["group:copy_user_viewables"].invoke
  # end
end
