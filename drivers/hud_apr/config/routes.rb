###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  scope module: :hud_apr, path: :hud_reports, as: :hud_reports do
    resources :aprs do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      resources :questions, only: [:show, :create], controller: 'apr/questions' do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show, controller: 'apr/cells'
      end
    end

    resources :capers do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      resources :questions, only: [:show, :create], controller: 'caper/questions' do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show, controller: 'caper/cells'
      end
    end
  end
end
