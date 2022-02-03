###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  resources :clients, only: [:index, :show, :new], controller: 'client_access_control/clients' do
    member do
      get :appropriate
      get :simple
      get :image
      get :enrollment_details
      get :from_source
    end
    resource :history, only: [:show], controller: 'client_access_control/history' do
      get :pdf, on: :collection
      post :queue, on: :collection
    end
  end
end
