class CleanupCaseManagerHmisColumns < ActiveRecord::Migration
  def change
    remove_column :hmis_clients, :case_manager_entity_id, :integer
    remove_column :hmis_clients, :consent_form_updated_at, :datetime
    add_column :hmis_clients, :case_manager_attributes, :text
    add_column :hmis_clients, :assigned_staff_name, :string
    add_column :hmis_clients, :assigned_staff_attributes, :text
    add_column :hmis_clients, :counselor_name, :string
    add_column :hmis_clients, :counselor_attributes, :text
    add_column :hmis_clients, :outreach_counselor_name, :string
  end
end
