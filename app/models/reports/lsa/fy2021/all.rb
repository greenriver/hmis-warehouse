###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# LEGACY REPORT — FY 2021 (retired, read-only)
#
# This file exists solely to preserve Rails STI resolution for historical report
# records stored with type = 'Reports::Lsa::Fy2021::All' or '...::Base'.
# FY 2021 LSA reports can no longer be generated. These classes support view-only
# access to past run data (downloads, result summaries) and nothing else.
#
# Do not add generation logic, update business rules, or extend these classes.
# The active LSA generator is HudLsa::Generators::Fy2026::Lsa.
module Reports::Lsa::Fy2021
  class Base < ::Report
    def self.report_name = 'LSA - FY 2021'
    def report_group_name = 'Longitudinal System Analysis '
    def download_type = :zip
    def value_for_options(options) = options.present? ? "CoC: #{options['coc_code']}" : ''
  end

  class All < Base
  end
end
