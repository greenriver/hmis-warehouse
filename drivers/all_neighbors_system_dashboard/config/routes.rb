BostonHmis::Application.routes.draw do
  namespace :all_neighbors_system_dashboard do
    namespace :warehouse_reports do
      resources :reports
    end
  end
end
