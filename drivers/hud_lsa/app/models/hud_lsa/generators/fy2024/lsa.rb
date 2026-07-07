###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Read-only stub: retains STI resolution, file downloads, and archival support.
# FY2024 reports can no longer be generated — only historical data is accessible.
module HudLsa::Generators::Fy2024
  class Lsa < ::HudReports::ReportInstance
    include HudLsa::Generators::RetiredLsaStub
  end
end
