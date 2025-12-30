###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

BostonHmis::Application.routes.draw do
  # TODO: build this out
  scope module: :hud_spm_report, path: :hud_reports, as: :hud_reports do
    resources :spms do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      resources :measures, only: [:show, :create] do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: [:show] do
          get :search, on: :member
          resources :search_queries, only: [:create], module: :cells
        end
      end
    end
    resources :legacy_spms, only: [:index, :show] do
      resources :legacy_results, only: [:show]
    end
  end
end
