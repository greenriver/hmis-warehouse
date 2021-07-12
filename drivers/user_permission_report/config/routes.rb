###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :user_permission_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
      resources :users, only: [:show]
    end
  end
end
