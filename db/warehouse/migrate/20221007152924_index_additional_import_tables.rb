class IndexAdditionalImportTables < ActiveRecord::Migration[6.1]
  def change
    add_index :hmis_2022_exits, [:EnrollmentID, :PersonalID, :importer_log_id, :data_source_id], name: :hmis_2022_exit_e_id_compound
    {
      disabilities: :DisabilitiesID,
      health_and_dvs: :HealthAndDVID,
      income_benefits: :IncomeBenefitsID,
      events: :EventID,
      services: :ServicesID,
    }.each do |table, hk|
      add_index "hmis_2022_#{table}", [hk, :importer_log_id], name: "hmis_2022_#{table}_hk_l_id"
    end
  end
end
