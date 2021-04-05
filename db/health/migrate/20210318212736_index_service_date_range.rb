class IndexServiceDateRange < ActiveRecord::Migration[5.2]
  def change
    add_index :claims_reporting_medical_claims,
      "daterange(service_start_date, service_end_date, '[]')",
      name: 'claims_reporting_medical_claims_service_daterange',
      using: 'gist'
  end
end
