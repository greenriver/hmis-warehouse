class AddMissingSystemPathwaysColumns < ActiveRecord::Migration[6.1]
  def change
    add_reference :system_pathways_clients, :report
    add_reference :system_pathways_enrollments, :report
    add_column :system_pathways_clients, :deleted_at, :datetime
    add_column :system_pathways_enrollments, :deleted_at, :datetime
  end
end
