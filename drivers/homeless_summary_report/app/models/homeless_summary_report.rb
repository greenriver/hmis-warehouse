###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HomelessSummaryReport
  def self.table_name_prefix
    'homeless_summary_report_'
  end

  REVISION_DATE = '2024-07-18'.to_date
end
