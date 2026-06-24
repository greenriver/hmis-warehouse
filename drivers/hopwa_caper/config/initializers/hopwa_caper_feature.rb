###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RailsDrivers.loaded << :hopwa_caper

Rails.application.config.hud_reports['HopwaCaper::Generators::Fy2024::Generator'] = {
  title: 'HOPWA CAPER',
  helper: 'hud_reports_hopwa_capers_path',
}

Rails.application.config.hud_reports['HopwaCaper::Generators::Fy2026::Generator'] = {
  title: 'HOPWA CAPER',
  helper: 'hud_reports_hopwa_capers_path',
}
