###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :system_pathways do
    namespace :warehouse_reports do
      resources :reports do
        get :details, on: :member
        get 'chart_data/:chart', to: 'reports#chart_data', on: :member, as: :chart_data
      end
    end
  end
end
