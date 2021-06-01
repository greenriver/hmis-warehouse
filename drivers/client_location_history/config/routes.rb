BostonHmis::Application.routes.draw do
  namespace :client_location_history do
    resources :clients, only: [:none] do
      get :map, on: :member
    end
    namespace :warehouse_reports do
      resources :client_location_history, only: [:index]
    end
  end
end
