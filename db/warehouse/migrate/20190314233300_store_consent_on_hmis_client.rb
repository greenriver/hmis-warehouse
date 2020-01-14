class StoreConsentOnHmisClient < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_clients, :consent_confirmed_on, :date
    add_column :hmis_clients, :consent_expires_on, :date
  end
end
