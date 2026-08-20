###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  scope :access_log do
    # TODO
    # get '/my_path', to: 'access_logs/my_controller'
  end
  namespace :access_logs do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create] do
        collection do
          get :report_usage
          post :render_report_usage
        end
      end
    end
  end
end
