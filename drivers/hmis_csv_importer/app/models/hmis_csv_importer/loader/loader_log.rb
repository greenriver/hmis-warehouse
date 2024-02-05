###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Loader
  class LoaderLog < GrdaWarehouseBase
    include HmisCsvImporter::HmisCsv
    include ActionView::Helpers::DateHelper

    self.table_name = 'hmis_csv_loader_logs'
    has_many :load_errors

    def successfully_loaded?
      status.to_s == 'loaded'
    end

    def load_time
      return unless persisted?

      if completed_at && started_at
        seconds = ((completed_at - started_at) / 1.minute).round * 60
        "#{distance_of_time_in_words(seconds)} -#{started_at.strftime('%l:%M %P')} to #{completed_at.strftime('%l:%M %P')}"
      else
        'processing...'
      end
    end
  end
end
