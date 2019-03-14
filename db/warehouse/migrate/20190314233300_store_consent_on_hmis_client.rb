class StoreConsentOnHmisClient < ActiveRecord::Migration
  def change
    add_column :hmis_clients, :consent_confirmed_date, :date
    add_column :hmis_clients, :consent_expires_date, :date
  end
end
