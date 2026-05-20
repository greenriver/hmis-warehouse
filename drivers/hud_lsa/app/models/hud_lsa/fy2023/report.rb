###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# STI stub — historical rows may exist with type = 'HudLsa::Fy2023::Report'.
module HudLsa::Fy2023
  class Report < ::Report
    def self.report_name = 'LSA - FY 2023'
  end
end
