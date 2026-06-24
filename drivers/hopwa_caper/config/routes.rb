###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  scope module: :hopwa_caper, path: :hud_reports, as: :hud_reports do
    resources :hopwa_capers, controller: :reports do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      resources :questions, only: [:show, :create] do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show
      end
    end
  end
end
