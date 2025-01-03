###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  resources :clients, only: [:none] do
    namespace :health_comprehensive_assessment do
      resources :assessments do
        resources :medications
        resources :sud_treatments
      end
    end
  end
end
