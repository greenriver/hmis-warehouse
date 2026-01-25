###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

BostonHmis::Application.routes.draw do
  namespace :homeless_summary_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get :details, on: :member
        post 'reload_from_csv', to: 'reports#reload_from_csv', as: :reload_from_csv, on: :member
      end
    end
  end
end
