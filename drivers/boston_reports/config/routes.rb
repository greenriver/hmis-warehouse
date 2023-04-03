###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :boston_reports do
    namespace :warehouse_reports do
      resources :street_to_homes, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'street_to_homes#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
        post :render_section, on: :collection
      end
      resources :configs, only: [:index, :update]
    end
  end
end
