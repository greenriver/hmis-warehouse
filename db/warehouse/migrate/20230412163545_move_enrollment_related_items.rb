class MoveEnrollmentRelatedItems < ActiveRecord::Migration[6.1]
  def change
    remove_column :system_pathways_clients, :disabling_condition, :boolean
    remove_column :system_pathways_clients, :relationship_to_hoh, :integer
    remove_column :system_pathways_clients, :household_id, :string
    remove_column :system_pathways_clients, :household_type, :string

    add_column :system_pathways_enrollments, :disabling_condition, :boolean
    add_column :system_pathways_enrollments, :relationship_to_hoh, :integer
    add_column :system_pathways_enrollments, :household_id, :string
    add_column :system_pathways_enrollments, :household_type, :string
  end
end
