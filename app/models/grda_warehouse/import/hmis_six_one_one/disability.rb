###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HMISSixOneOne
  class Disability < GrdaWarehouse::Hud::Disability
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :DisabilitiesID
    setup_hud_column_access( GrdaWarehouse::Hud::Disability.hud_csv_headers(version: '6.11') )

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