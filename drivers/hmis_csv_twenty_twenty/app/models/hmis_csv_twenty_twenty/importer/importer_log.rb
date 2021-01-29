###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class ImporterLog < GrdaWarehouseBase
    self.table_name = 'hmis_csv_importer_logs'

    has_many :import_errors
    has_many :import_validations, class_name: 'HmisCsvValidation::Base'
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    def paused?
      status.to_s == 'paused'
    end

    def resuming?
      status.to_s == 'resuming'
    end
  end
end
