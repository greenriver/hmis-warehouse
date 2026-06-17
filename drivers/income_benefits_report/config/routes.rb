###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :income_benefits_report do
    namespace :warehouse_reports do
      resources :report, only: [:index, :create, :destroy, :show] do
        get :details, on: :member
        get 'section/:partial', on: :collection, to: 'report#section', as: :section
        get :filters, on: :collection
        get :download, on: :member
      end
    end
  end
end
