BostonHmis::Application.routes.draw do
  namespace :override_summary do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
    end
  end
end
