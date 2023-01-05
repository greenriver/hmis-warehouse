class AddProjectGroupIdToCohorts < ActiveRecord::Migration[6.1]
  def change
    add_reference :cohorts, :project_group
  end
end
