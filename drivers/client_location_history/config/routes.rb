###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :client_location_history do
    resources :clients, only: [] do
      get :map, on: :member
    end
    resources :projects, only: [] do
      get :map, on: :member
    end
    namespace :warehouse_reports do
      resources :client_location_history, only: [:index]
    end
  end
end
