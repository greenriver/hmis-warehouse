###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared route patterns for HUD reports across driver modules.
module HudReports
  module RouteConcerns
    def self.extended(base)
      base.instance_eval do
        # Standard collection and member routes for HUD reports
        # - running: poll for reports currently generating
        # - running_all_questions: poll for all questions being processed
        # - history: view past report runs
        # - download: export completed report
        concern :hud_report_actions do
          get :running, on: :collection
          get :running_all_questions, on: :collection
          get :history, on: :collection
          get :download, on: :member
        end

        # Nested routes for drilling down into report data via questions/measures and cells
        # Options:
        #   :resource - override default :questions resource name (e.g., resource: :measures for SPM reports)
        concern :hud_drilldown_actions do |options|
          resources options[:resource] || :questions, only: [:show, :create] do
            get :result, on: :member
            get :running, on: :member
            resources :cells, only: [:show] do
              get :search, on: :member
              resources :search_queries, only: [:create], module: :cells
            end
          end
        end
      end
    end
  end
end
