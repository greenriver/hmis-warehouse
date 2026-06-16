###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :built_for_zero_report do
    namespace :warehouse_reports do
      resources :bfz, only: [:index] do
        get :details, on: :collection
      end
    end
  end
end
