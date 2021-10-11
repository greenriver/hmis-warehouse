###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class ImporterLog < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    self.table_name = 'hmis_csv_importer_logs'

    has_many :import_errors
    has_many :import_validations, class_name: 'HmisCsvValidation::Base'
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true

    def paused?
      status.to_s == 'paused'
    end

    def resuming?
      status.to_s == 'resuming'
    end

    def import_time
      return unless persisted?
      # Historically we didn't set started_at
      return unless started_at

      if completed_at && started_at
        seconds = ((completed_at - started_at) / 1.minute).round * 60
        distance_of_time_in_words(seconds)
      else
        'processing...'
      end
    end
  end
end
