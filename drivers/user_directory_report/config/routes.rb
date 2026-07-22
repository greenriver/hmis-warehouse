###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :user_directory_report do
    namespace :warehouse_reports do
      resources :users, only: [] do
        get :warehouse, on: :collection
        get :cas, on: :collection
      end
    end
  end
end
