###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :data_source_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index] do
      end
    end
  end
end
