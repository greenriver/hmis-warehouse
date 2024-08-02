###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HomelessSummaryReport
  def self.table_name_prefix
    'homeless_summary_report_'
  end

  REVISION_DATE = '2024-07-18'.to_date
end
