class AddColumnsToContactTracingContacts < ActiveRecord::Migration[5.2]
  def change
    add_column :tracing_contacts, :symptoms, :jsonb
    add_column :tracing_contacts, :other_symptoms, :string
  end
end
