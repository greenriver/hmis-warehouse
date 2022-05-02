###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :claims_reporting do
    namespace :warehouse_reports do
      resources :reconciliation, only: [:index, :create]
      resources :performance, only: [:index, :create]
      resources :engagement_trends, only: [:index, :show, :destroy, :create]
      resources :quality_measures, only: [:index, :show, :destroy, :create]
      resources :imports, only: [:index]
    end
  end
end
