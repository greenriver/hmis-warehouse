###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# LEGACY REPORT — FY 2021 (retired, read-only)
#
# STI stub for historical ReportResultsSummary records. No new summaries will be
# generated for this fiscal year. Exists only to prevent STI resolution errors
# when loading past run data. See Reports::Lsa::Fy2021 for the corresponding Report stub.
module ReportResultsSummaries::Lsa
  class Fy2021 < ::ReportResultsSummary
  end
end
