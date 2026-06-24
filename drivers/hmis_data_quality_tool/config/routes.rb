###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :hmis_data_quality_tool do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get :items, on: :member
        get :by_client, on: :member
        get :by_chart, on: :member
      end
      resources :goal_configs, except: [:show]
    end
  end
end
