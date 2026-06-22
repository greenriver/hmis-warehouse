###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# STI stub — historical rows may exist with type = 'HudLsa::Fy2022::Report'.
module HudLsa::Fy2022
  class Report < ::Report
    def self.report_name = 'LSA - FY 2022'
  end
end
