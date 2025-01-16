###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :financial do
    resources :clients, only: [:show] do
      get 'rollup/:partial', to: 'clients#rollup', as: :rollup
    end
  end
end
