###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :user_directory_report do
    namespace :warehouse_reports do
      resources :users, only: [:none] do
        get :warehouse, on: :collection
        get :cas, on: :collection
      end
    end
  end
end
