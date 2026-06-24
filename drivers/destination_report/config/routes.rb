###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
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
