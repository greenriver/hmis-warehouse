BostonHmis::Application.routes.draw do
  namespace :all_neighbors_system_dashboard do
    namespace :warehouse_reports do
      resources :reports do
        member do
          get :internal
          get :raw
          get :debug
        end
      end
    end
  end
end
