###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.routes.draw do
  namespace :core_demographics_report do
    namespace :warehouse_reports do
      resources :core, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'core#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
        post :render_section, on: :collection
      end
    end
  end
end
