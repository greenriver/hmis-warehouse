BostonHmis::Application.routes.draw do
  namespace :claims_reporting do
    namespace :warehouse_reports do
      resources :reconciliation, only: [:index, :create]
      resources :performance, only: [:index, :create]
    end
  end
end
