###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.routes.draw do
  namespace :tx_client_reports do
    namespace :warehouse_reports do
      resources :attachment_three_client_data_reports, only: [:index]
      resources :research_exports, only: [:index, :show, :create, :destroy]
    end
  end
end
