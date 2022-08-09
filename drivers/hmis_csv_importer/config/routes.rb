###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  namespace :hmis_csv_importer do
    resources :loader_errors, only: [:show]
    get 'importer_validations/:id/:file', to: 'importer_validations#show', as: :importer_validation
    get 'importer_validation_errors/:id/:file', to: 'importer_validation_errors#show', as: :importer_validation_error
    # NOTE: importer_errors/:id/download must come before importer_errors/:id/:file
    get 'download_importer_errors/:id', to: 'importer_errors#download', as: :importer_errors
    get 'importer_errors/:id/:file', to: 'importer_errors#show', as: :importer_error
    get 'importer_validations/:id/:file/download', to: 'importer_validations#download', as: :importer_validation_download
    resources :importer_extensions, only: [:edit, :update]
    resources :loaded, only: [:show]
    resources :imported, only: [:show]
    resources :importer_restarts, only: [:update]
  end
end
