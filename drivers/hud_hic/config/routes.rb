###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  scope module: :hud_hic, path: :hud_reports, as: :hud_reports do
    resources :hics do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      resources :questions, only: [:show, :create] do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show
      end
    end
  end
end
