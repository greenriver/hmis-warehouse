###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :user_permission_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
      resources :users, only: [:show]
    end
  end
end
