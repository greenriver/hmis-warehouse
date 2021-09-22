###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Loader
  class LoaderLog < GrdaWarehouseBase
    include HmisTwentyTwenty
    include ActionView::Helpers::DateHelper

    self.table_name = 'hmis_csv_loader_logs'
    has_many :load_errors

    def self.module_scope
      'HmisCsvImporter::Loader'
    end

    def successfully_loaded?
      status.to_s == 'loaded'
    end

    def load_time
      return unless persisted?

      if completed_at && started_at
        seconds = ((completed_at - started_at) / 1.minute).round * 60
        distance_of_time_in_words(seconds)
      else
        'processing...'
      end
    end
  end
end
