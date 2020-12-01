BostonHmis::Application.routes.draw do
  namespace :hmis_csv_twenty_twenty do
    resources :loader_errors, only: [:show]
    resources :importer_validations, only: [:show]
    resources :importer_errors, only: [:show]
    resources :importer_extensions, only: [:show]
    resources :loaded, only: [:show]
    resources :imported, only: [:show]
  end
end
