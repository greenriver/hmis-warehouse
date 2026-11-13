###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.hud_reports['HudPathReport::Generators::Fy2020::Generator'] = {
  title: 'Annual PATH Report',
  helper: 'hud_reports_paths_path',
}

Rails.application.config.hud_reports['HudPathReport::Generators::Fy2021::Generator'] = {
  title: 'Annual PATH Report',
  helper: 'hud_reports_paths_path',
}

Rails.application.config.hud_reports['HudPathReport::Generators::Fy2024::Generator'] = {
  title: 'Annual PATH Report',
  helper: 'hud_reports_paths_path',
}

Rails.application.config.hud_reports['HudPathReport::Generators::Fy2026::Generator'] = {
  title: 'Annual PATH Report',
  helper: 'hud_reports_paths_path',
}
