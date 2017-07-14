class IndexActAsProjectTypeAndProjectType < ActiveRecord::Migration
  def up
    execute 'CREATE index "project_project_override_index" ON "Project" (COALESCE("act_as_project_type", "ProjectType"));'
    # add_index :Project, 'COALESCE("act_as_project_type", "ProjectType")'
  end

  def down
    execute 'DROP INDEX IF EXISTS "project_project_override_index"'
  end
end
