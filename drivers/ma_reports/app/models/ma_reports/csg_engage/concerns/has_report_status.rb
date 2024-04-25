###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::Concerns::HasReportStatus
  extend ActiveSupport::Concern
  included do
    [
      :completed,
      :failed,
      :in_progress,
      :created,
      :unknown,
    ].each do |status_value|
      define_method(:"#{status_value}?") { status == status_value }
    end

    def status
      return :completed if completed_at.present?
      return :failed if failed_at.present?
      return :in_progress if started_at.present?
      return :created if created_at.present?

      return :unknown
    end

    def not_started?
      return false if completed? || failed? || in_progress? || unknown?

      true
    end

    def status_text
      {
        completed: 'Completed',
        failed: 'Failed',
        in_progress: 'In Progress',
        created: 'Created',
        unknown: 'Unknown',
      }[status]
    end
  end
end
