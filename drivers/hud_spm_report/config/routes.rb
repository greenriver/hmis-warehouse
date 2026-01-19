###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../lib/hud_reports/route_concerns'

BostonHmis::Application.routes.draw do
  extend HudReports::RouteConcerns

  # TODO: build this out
  scope module: :hud_spm_report, path: :hud_reports, as: :hud_reports do
    resources :spms do
      concerns :hud_report_actions
      concerns :hud_drilldown_actions, resource: :measures
    end
    resources :legacy_spms, only: [:index, :show] do
      resources :legacy_results, only: [:show]
    end
  end
end
