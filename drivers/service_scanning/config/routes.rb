Rails.application.routes.draw do
  namespace :service_scanning do
    resources :services do
      get :new_client, on: :collection
      post :create_client, on: :collection
    end
    resources :scanner_ids
  end
end
