class IndexClaimsOnServiceStart < ActiveRecord::Migration[5.2]
  def change
    add_index :claims_reporting_rx_claims, :service_start_date
    add_index :claims_reporting_medical_claims, :service_start_date
  end
end
