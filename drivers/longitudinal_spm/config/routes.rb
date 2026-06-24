###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :longitudinal_spm do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get :history, on: :collection
      end
    end
  end
end
