module GrdaWarehouse::Import::HMISSixOneOne
  class EnrollmentCoc < GrdaWarehouse::Hud::EnrollmentCoc
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :EnrollmentCoCID
    setup_hud_column_access( GrdaWarehouse::Hud::EnrollmentCoc.hud_csv_headers(version: '6.11') )

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'EnrollmentCoC.csv'
    end

  end
end