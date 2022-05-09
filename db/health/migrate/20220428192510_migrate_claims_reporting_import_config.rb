class MigrateClaimsReportingImportConfig < ActiveRecord::Migration[6.1]
  def change
    credentials = Health::ImportConfig.find_by(name: 'ONE')&.dup
    if credentials.present?
      credentials.assign_attributes(
        name: 'MassHealth',
        kind: :claims_reporting,
        path: GrdaWarehouse::Config.get(:health_claims_data_path),
      )
      credentials.save!
    end
  end
end
