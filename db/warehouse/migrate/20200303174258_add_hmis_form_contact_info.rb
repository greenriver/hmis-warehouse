class AddHmisFormContactInfo < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_forms, :client_phones, :string
    add_column :hmis_forms, :client_emails, :string
    add_column :hmis_forms, :client_shelters, :string
    add_column :hmis_forms, :client_case_managers, :string
    add_column :hmis_forms, :client_day_shelters, :string
    add_column :hmis_forms, :client_night_shelters, :string
  end
end
