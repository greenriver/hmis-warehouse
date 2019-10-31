class AddContactToCasReport < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :event_contact, :string
    add_column :cas_reports, :event_contact_agency, :string
  end
end
