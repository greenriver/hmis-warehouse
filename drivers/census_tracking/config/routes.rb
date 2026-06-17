###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :census_tracking do
    namespace :warehouse_reports do
      resources :census_trackers, only: [:index] do
        collection do
          get :details
        end
      end
    end
  end
end
