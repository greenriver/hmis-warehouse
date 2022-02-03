###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  scope :access_log do
    # TODO
    # get '/my_path', to: 'access_logs/my_controller'
  end
  namespace :access_logs do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
    end
  end
end
