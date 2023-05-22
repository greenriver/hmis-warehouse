###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  # Routes for the HMIS API
  if ENV['ENABLE_HMIS_API'] == 'true'
    namespace :hmis, defaults: { format: :json } do
      devise_for :users, class_name: 'Hmis::User',
                         skip: [:registrations, :invitations, :passwords, :confirmations, :unlocks, :password_expired],
                         controllers: { sessions: 'hmis/sessions' },
                         path: '', path_names: { sign_in: 'login', sign_out: 'logout' }

      resources :user, only: [:none] do
        get :index, on: :collection
      end

      devise_scope :hmis_user do
        match 'logout' => 'sessions#destroy', via: :get if Rails.env.development?
        if ENV['OKTA_DOMAIN'].present?
          get '/users/auth/okta/callback' => 'users/omniauth_callbacks#okta' if ENV['HMIS_OKTA_CLIENT_ID']
        end
      end

      get 'theme', to: 'theme#index', defaults: { format: :json }
      get 'themes', to: 'theme#list', defaults: { format: :json }
      resource 'app_settings', only: [:show], defaults: { format: :json }

      post 'hmis-gql', to: 'graphql#execute', defaults: { schema: :hmis }
      mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/hmis/hmis-gql', defaults: { format: :html } if Rails.env.development?

      # Fall back to HMIS origin for any other `hmis/*` route.
      # We need this because the frontend proxies ALL requests to hmis/* to the backend.
      # Note: in a development environment, this ends up redirecting to the warehouse.
      get '*other', to: redirect { |_, req| req.origin }
    end
    namespace :hmis_admin do
      resources :roles
      resources :groups
      resources :access_controls do
        resources :users, only: [:create, :destroy], controller: 'access_controls/users'
      end
    end
  end
end
