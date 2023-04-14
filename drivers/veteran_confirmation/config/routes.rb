###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :clients do
    resources :veteran_confirmations, only: [:show], controller: '/veteran_confirmation/veteran_confirmations'
  end
end
