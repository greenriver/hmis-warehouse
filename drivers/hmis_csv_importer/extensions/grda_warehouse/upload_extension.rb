###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::GrdaWarehouse
  module UploadExtension
    extend ActiveSupport::Concern

    included do
      has_one :importer_log, through: :import_log
      has_one :loader_log, through: :import_log

      def status
        if percent_complete.zero?
          'Queued'
        elsif percent_complete.to_d == 0.01.to_d
          'Started'
        elsif percent_complete == 100
          return 'Paused for error review' if importer_log&.paused?

          'Complete'
        else
          percent_complete
        end
      end

      def import_time(details: false)
        if delayed_job.present?
          return "Failed with: #{delayed_job.last_error.split("\n").first}" if delayed_job.last_error.present? && details
          return 'failed' if delayed_job.failed_at.present? || delayed_job.last_error.present?
        end
        if percent_complete == 100
          return 'Paused for error review' if importer_log&.paused?
          return 'Resuming...' if importer_log&.resuming?

          begin
            seconds = ((completed_at - created_at) / 1.minute).round * 60
            distance_of_time_in_words(seconds)
          rescue StandardError
            'unknown'
          end
        else
          return 'failed' if updated_at < 2.days.ago

          'processing...'
        end
      end
    end
  end
end
