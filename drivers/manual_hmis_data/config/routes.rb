###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :manual_hmis_data do
    resources :projects, only: [:none] do
      resources :funders, shallow: true, except: [:index, :show]
      resources :inventories, shallow: true, except: [:index, :show]
      resources :project_cocs, shallow: true, except: [:index, :show]
    end
  end
end
