###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  scope module: :hud_lsa, path: :hud_reports, as: :hud_reports do
    resources :lsas do
      get :new_hic, on: :collection
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :missing_data, on: :collection
      get :download, on: :member
      get :download_intermediate, on: :member
    end
  end
end
