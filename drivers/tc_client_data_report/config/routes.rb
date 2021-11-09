###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.routes.draw do
  namespace :tc_client_data_report do
    namespace :warehouse_reports do
      resources :tc_client_data_reports, only: [:index]
    end
  end
end
