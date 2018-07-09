module GrdaWarehouse::Import::HMISSixOneOne
  class IncomeBenefit < GrdaWarehouse::Hud::IncomeBenefit
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :IncomeBenefitsID
    setup_hud_column_access(  GrdaWarehouse::Hud::IncomeBenefit.hud_csv_headers(version: '6.11') )

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'IncomeBenefits.csv'
    end

  end
end