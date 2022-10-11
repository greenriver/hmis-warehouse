###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  # NOTE: using only: [:none] because leaving it blank inserts the default routes, which we have moved to a driver
  resources :clients, only: [:none] do
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
