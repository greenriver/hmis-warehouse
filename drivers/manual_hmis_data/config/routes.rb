###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  namespace :manual_hmis_data do
    resources :projects, only: [:none] do
      resources :funders, shallow: true, except: [:index, :show]
      resources :inventories, shallow: true, except: [:index, :show]
      resources :project_cocs, shallow: true, except: [:index, :show]
    end
  end
end
