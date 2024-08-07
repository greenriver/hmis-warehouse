###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :performance_measurement do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :update, :destroy] do
        get 'details/:key', to: 'reports#details', as: :details
        get 'clients/:key/:project_id', to: 'reports#clients', as: :clients
        member do
          get 'equity_analysis', to: 'reports#equity_analysis', as: :equity_analysis
        end
      end
      resources :goal_configs, except: [:show] do
        resources :pit_counts, only: [:new, :create, :destroy]
        resources :static_spms, except: [:show]
        post :duplicate, on: :member
      end
    end
  end
end
