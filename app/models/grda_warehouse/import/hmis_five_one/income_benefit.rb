module GrdaWarehouse::Import::HMISFiveOne
  class IncomeBenefit < GrdaWarehouse::Hud::IncomeBenefit
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( GrdaWarehouse::Hud::IncomeBenefit.hud_csv_headers(version: '5.1') )

    self.hud_key = :IncomeBenefitsID

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'IncomeBenefits.csv'
    end
  end
end