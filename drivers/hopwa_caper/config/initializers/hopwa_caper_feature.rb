###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RailsDrivers.loaded << :hopwa_caper

Rails.application.config.hud_reports['HopwaCaper::Generators::Fy2024::Generator'] = {
  title: 'HOPWA CAPER',
  helper: 'hud_reports_hopwa_capers_path',
}
