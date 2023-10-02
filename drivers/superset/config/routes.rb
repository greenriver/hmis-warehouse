BostonHmis::Application.routes.draw do
  namespace :superset do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
    end
  end
end
