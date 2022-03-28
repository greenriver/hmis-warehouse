###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :analysis_tool do
    namespace :warehouse_reports do
      resources :analysis_tool, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'analysis_tool#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
        post :render_section, on: :collection
      end
    end
  end
end
