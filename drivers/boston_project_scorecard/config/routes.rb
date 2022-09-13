###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.routes.draw do
  namespace :boston_project_scorecard do
    namespace :warehouse_reports do
      resources :scorecards, only: [:index, :create, :show, :edit, :update] do
        get :history, on: :collection
        get :complete, on: :member
        get :rewind, on: :member
      end
    end
  end
end
