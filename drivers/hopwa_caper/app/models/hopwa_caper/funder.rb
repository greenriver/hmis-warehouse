###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper
  class Funder < ::HudReports::ReportClientBase
    self.table_name = 'hopwa_caper_funders'

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :report, class_name: 'HudReports::ReportInstance', foreign_key: :report_instance_id

    scope :within_range, ->(range) do
      a_t = arel_table
      end_ok   = a_t[:end_date].eq(nil).or(a_t[:end_date].gteq(range.first))     unless range.begin.nil?
      start_ok = a_t[:start_date].eq(nil).or(a_t[:start_date].lteq(range.last))  unless range.end.nil?

      where(end_ok).where(start_ok)
    end

    def within_range?(range)
      # Overlap fails only if one interval is entirely before or after the other.
      # nil start = -infinity, nil end = +infinity
      end_ok = end_date.nil? || range.begin.nil? || end_date >= range.first
      start_ok = start_date.nil? || range.end.nil? || start_date <= range.last
      end_ok && start_ok
    end

    def self.from_hud_record(funder:, report:, project:)
      new(
        report_instance_id: report.id,
        code: funder.funder.to_i,
        start_date: funder.start_date,
        end_date: funder.end_date,
        funder_id: funder.id,
        project_id: project.id,
      )
    end
  end
end
