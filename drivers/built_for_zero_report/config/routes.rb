# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :built_for_zero_report do
    namespace :warehouse_reports do
      resources :bfz, only: [:index] do
        get :details, on: :collection
      end
    end
  end
end
