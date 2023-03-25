class AddLastIntentionalContacts < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_clients_processed, :last_intentional_contacts, :string
  end
end
