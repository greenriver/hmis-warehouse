###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  resources :data_sources, only: [] do
    namespace :hmis_supplemental do
      resources :data_sets do
        resource :upload, only: [:create, :new], controller: 'data_set_uploads'
      end
    end
  end
  namespace :hmis_supplemental do
    resources :data_sets, only: [] do
      resources :client_data_sets, only: [:show]
    end
  end
end
