###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.routes.draw do
  namespace :census_tracking do
    namespace :warehouse_reports do
      resources :census_trackers, only: [:index] do
        collection do
          get :details
        end
      end
    end
  end
end
