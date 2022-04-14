BostonHmis::Application.routes.draw do
  namespace :start_date_dq do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
    end
  end
end
