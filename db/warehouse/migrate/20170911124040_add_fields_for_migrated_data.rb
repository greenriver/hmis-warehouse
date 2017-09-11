class AddFieldsForMigratedData < ActiveRecord::Migration
  def change
    add_column :client_notes, :migrated_username, :string
    add_column :files, :migrated_username, :string
    add_column :vispdats, :migrated_case_manager, :string
    add_column :vispdats, :migrated_interviewer_name, :string
    add_column :vispdats, :migrated_interviewer_email, :string
    add_column :vispdats, :migrated_filed_by, :string
  end
end
