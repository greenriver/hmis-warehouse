###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :disability_summary do
    namespace :warehouse_reports do
      resources :disability_summary, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'disability_summary#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
        post :render_section, on: :collection
      end
    end
  end
end
