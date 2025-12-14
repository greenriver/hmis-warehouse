# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports
  class ReportCheckpoint < GrdaWarehouseBase
    self.table_name = 'hud_report_checkpoints'
    belongs_to :report_instance, class_name: 'HudReports::ReportInstance', foreign_key: 'hud_report_instance_id'

    validates :status, inclusion: { in: ['running', 'success', 'error'] }

    def completed_and_valid?
      status == 'success' && completed_at && completed_at >= started_at
    end

    def self.calculate_duration_seconds
      # Collect all valid intervals
      return nil if current_scope.empty?

      intervals = current_scope.filter(&:completed_and_valid?).
        sort_by { |cp| [cp.started_at, cp.completed_at, cp.id] }.
        filter_map { |cp| [cp.started_at, cp.completed_at] }

      # Don't bother checking overlapping intervals as this should be impossible
      intervals.sum { |s, e| e - s }
    end
  end
end
