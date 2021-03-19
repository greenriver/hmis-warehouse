###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
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
