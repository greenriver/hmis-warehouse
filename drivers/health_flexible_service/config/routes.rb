###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  # NOTE: using only: [:none] because leaving it blank inserts the default routes, which we have moved to a driver
  resources :clients, only: [:none] do
    namespace :health_flexible_service do
      resources :vprs
    end
  end

  namespace :health_flexible_service do
    namespace :warehouse_reports do
      resources :member_lists, only: [:index, :create]
    end
  end
end
