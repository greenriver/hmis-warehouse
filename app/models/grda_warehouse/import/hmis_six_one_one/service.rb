###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HMISSixOneOne
  class Service < GrdaWarehouse::Hud::Service
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :ServicesID
    setup_hud_column_access( GrdaWarehouse::Hud::Service.hud_csv_headers(version: '6.11') )

    def self.date_provided_column
      :DateProvided
    end

    def self.file_name
      'Services.csv'
    end

    def self.should_log?
      true
    end

    def self.to_log
      @to_log ||= {
        hud_key: self.hud_key,
        personal_id: :PersonalID,
        effective_date: :DateProvided,
        data_source_id: :data_source_id,
      }
    end
  end
end