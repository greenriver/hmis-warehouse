class CreateReportingProjects < ActiveRecord::Migration[4.2]
  # actually just add a column to the Project table to facilitate reporting
  def change
    add_column :Project, :act_as_project_type, :integer
  end
end
