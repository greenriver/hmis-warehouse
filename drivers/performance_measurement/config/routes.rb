BostonHmis::Application.routes.draw do
  namespace :performance_measurement do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get 'details/:key', to: 'reports#details', as: :details
      end
    end
  end
end
