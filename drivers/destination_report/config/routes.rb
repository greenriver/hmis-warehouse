###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :destination_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'reports#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
      end
    end
  end
end
