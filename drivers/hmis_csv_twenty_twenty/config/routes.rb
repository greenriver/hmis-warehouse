BostonHmis::Application.routes.draw do
  namespace :hmis_csv_twenty_twenty do
    resources :loader_errors, only: [:show]
    get 'importer_validations/:id/:file', to: 'importer_validations#show', as: :importer_validation
    get 'importer_validation_errors/:id/:file', to: 'importer_validation_errors#show', as: :importer_validation_error
    get 'importer_errors/:id/:file', to: 'importer_errors#show', as: :importer_error
    resources :importer_extensions, only: [:edit, :update]
    resources :loaded, only: [:show]
    resources :imported, only: [:show]
    resources :importer_restarts, only: [:update]
  end
end
