###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  resources :clients, only: [:none] do
    namespace :health_comprehensive_assessment do
      resources :assessments do
        resources :medications
        resources :sud_treatments
      end
    end
  end
end
