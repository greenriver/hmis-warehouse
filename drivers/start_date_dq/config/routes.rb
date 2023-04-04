###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :start_date_dq do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
    end
  end
end
