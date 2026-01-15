###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

BostonHmis::Application.routes.draw do
  scope module: :hud_apr, path: :hud_reports, as: :hud_reports do
    resources :aprs do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      scope module: :apr do
        resources :questions, only: [:show, :create] do
          get :result, on: :member
          get :running, on: :member
          resources :cells, only: [:show] do
            get :search, on: :member
            resources :search_queries, only: [:create], module: :cells
          end
        end
      end
    end

    resources :capers do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      scope module: :caper do
        resources :questions, only: [:show, :create] do
          get :result, on: :member
          get :running, on: :member
          resources :cells, only: [:show] do
            get :search, on: :member
            resources :search_queries, only: [:create], module: :cells
          end
        end
      end
    end

    resources :ce_aprs do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      scope module: :ce_apr do
        resources :questions, only: [:show, :create] do
          get :result, on: :member
          get :running, on: :member
          resources :cells, only: [:show] do
            get :search, on: :member
            resources :search_queries, only: [:create], module: :cells
          end
        end
      end
    end

    resources :dqs do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      scope module: :dq do
        resources :questions, only: [:show, :create] do
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
