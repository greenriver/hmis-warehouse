BostonHmis::Application.routes.draw do
  namespace :hmis_csv_twenty_twenty do
    resources :loader_errors, only: [:show]
  end
end
