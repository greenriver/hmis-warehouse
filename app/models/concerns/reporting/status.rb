###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::Status
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper
  included do
    def status
      return "Queued at #{created_at}" if started_at.blank?
      return 'Failed' if failed?
      return "Completed in #{run_time}" if completed?
      return 'Failed' if started_at.present? && started_at < 24.hours.ago

      "Running for #{running_for}"
    end

    def completed?
      completed_at.present?
    end

    def started?
      !completed? && started_at.present?
    end

    def running_for
      distance_of_time_in_words(started_at, Time.current)
    end

    def run_time
      distance_of_time_in_words(started_at, completed_at)
    end

    def failed?
      return false if started_at.blank?
      return false if completed_at.present?
      return true if started_at.present? && started_at < 24.hours.ago
      return false unless respond_to?(:failed_at)

      failed_at.present?
    end
  end
end
