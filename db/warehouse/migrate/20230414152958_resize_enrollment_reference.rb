class ResizeEnrollmentReference < ActiveRecord::Migration[6.1]
  def change
    change_column :system_pathways_clients, :returned_project_enrollment_id, :bigint
    change_column :system_pathways_clients, :returned_project_project_id, :bigint
  end
end
