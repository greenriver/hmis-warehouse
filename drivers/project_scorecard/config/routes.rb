###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :project_scorecard do
    namespace :warehouse_reports do
      resources :scorecards, only: [:index, :create, :show, :edit, :update] do
        get :history, on: :collection
        get :complete, on: :member
        get :rewind, on: :member
      end
    end
  end
end
