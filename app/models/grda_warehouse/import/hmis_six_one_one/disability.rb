module GrdaWarehouse::Import::HMISSixOneOne
  class Disability < GrdaWarehouse::Hud::Disability
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '6.11') )

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'Disabilities.csv'
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
       # We've seen a bunch of integers come through as floats
      row[:TCellCount] = row[:TCellCount].to_i
      return row
    end

  end
end