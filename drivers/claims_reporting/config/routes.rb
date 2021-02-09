###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :claims_reporting do
    resources :imports, only: [:index, :create]
    namespace :warehouse_reports do
      resources :reconciliation, only: [:index, :create]
      resources :performance, only: [:index, :create]
    end
  end
end
