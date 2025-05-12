###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

BostonHmis::Application.routes.draw do
  namespace :inactive_client_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index] do
        get :data, on: :collection
        post :render_section, on: :collection
        get :filters, on: :collection
        # get :download, on: :collection
      end
    end
  end
end
