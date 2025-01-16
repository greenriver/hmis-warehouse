###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  scope :zip_code_report do
    # TODO
    # get '/my_path', to: 'zip_code_report/my_controller'
  end
  namespace :zip_code_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index] do
        get :filters, on: :collection
      end
    end
  end
end
