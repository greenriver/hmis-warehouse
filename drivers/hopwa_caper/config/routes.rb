###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../lib/hud_reports/route_concerns'

BostonHmis::Application.routes.draw do
  extend HudReports::RouteConcerns

  scope module: :hopwa_caper, path: :hud_reports, as: :hud_reports do
    resources :hopwa_capers, controller: :reports do
      concerns :hud_report_actions
      concerns :hud_drilldown_actions
    end
  end
end
