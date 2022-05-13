###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class NonHmisUpload < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    acts_as_paranoid

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :user, optional: true

    belongs_to :delayed_job, optional: true, class_name: '::Delayed::Job'

    mount_uploader :file, ImportUploader
    validates :data_source, presence: true
    validates :file, presence: true, on: :create

    def status
      if percent_complete&.zero?
        'Queued'
      elsif percent_complete == 0.01
        'Started'
      elsif percent_complete == 100
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
        begin
          seconds = ((completed_at - created_at) / 1.minute).round * 60
          distance_of_time_in_words(seconds)
        rescue StandardError
          'unknown'
        end
      else
        'incomplete'
      end
    end
  end
end
