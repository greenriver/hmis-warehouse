###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  # NOTE: using only: [] because leaving it blank inserts the default routes, which we have moved to a driver
  resources :clients, only: [] do
    namespace :health_flexible_service do
      resource :staff, only: [:update]
      resources :vprs do
        resources :follow_ups, except: [:index]
      end
    end
  end

  namespace :health_flexible_service do
    resources :my_vprs, only: [:index]
    namespace :warehouse_reports do
      resources :member_lists, only: [:index, :create]
      resources :member_expiration, only: [:index]
    end
  end
end
