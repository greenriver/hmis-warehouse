###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.hud_reports['HudSpmReport::Generators::Fy2020::Generator'] = {
  title: 'System Performance Measures',
  helper: 'hud_reports_spms_path',
}

Rails.application.config.hud_reports['HudSpmReport::Generators::Fy2023::Generator'] = {
  title: 'System Performance Measures',
  helper: 'hud_reports_spms_path',
}

Rails.application.config.hud_reports['HudSpmReport::Generators::Fy2024::Generator'] = {
  title: 'System Performance Measures',
  helper: 'hud_reports_spms_path',
}

Rails.application.config.hud_reports['HudSpmReport::Generators::Fy2026::Generator'] = {
  title: 'System Performance Measures',
  helper: 'hud_reports_spms_path',
}
