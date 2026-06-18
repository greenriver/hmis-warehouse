###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :all_neighbors_system_dashboard do
    namespace :warehouse_reports do
      resources :reports do
        member do
          get :internal
          get :raw
          get :debug
          post :reload_from_csv
        end
      end
    end
  end
end
