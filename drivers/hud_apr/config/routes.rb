###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  extend HudReports::RouteConcerns

  scope module: :hud_apr, path: :hud_reports, as: :hud_reports do
    # APR (Annual Performance Report)
    resources :aprs do
      concerns :hud_report_actions
      scope module: :apr do
        concerns :hud_drilldown_actions
      end
    end

    # CAPER (Consolidated Annual Performance and Evaluation Report)
    resources :capers do
      concerns :hud_report_actions
      scope module: :caper do
        concerns :hud_drilldown_actions
      end
    end

    # CE APR (Coordinated Entry Annual Performance Report)
    resources :ce_aprs do
      concerns :hud_report_actions
      scope module: :ce_apr do
        concerns :hud_drilldown_actions
      end
    end

    # DQ (Data Quality Report)
    resources :dqs do
      concerns :hud_report_actions
      scope module: :dq do
        concerns :hud_drilldown_actions
      end
    end
  end
end
