###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.hud_reports['HudHic::Generators::Hic::Fy2022::Generator'] = {
  title: 'Housing Inventory Count',
  helper: 'hud_reports_hics_path',
}
