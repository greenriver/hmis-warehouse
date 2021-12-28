BostonHmis::Application.routes.draw do
  namespace :performance_measurement do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get 'details/:key', to: 'reports#details', as: :details
        get 'clients/:key/:project_id', to: 'reports#clients', as: :clients
      end
    end
  end
end
