###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

BostonHmis::Application.routes.draw do
  get 'hmis/system_status/operational', to: 'system_status#operational'
  get 'hmis/system_status/cache_status', to: 'system_status#cache_status'
  get 'hmis/system_status/details', to: 'system_status#details'
  get 'hmis/system_status/ping', to: 'system_status#ping'
  get 'hmis/system_status/exception', to: 'system_status#exception'

  # Routes for the HMIS API
  if ENV['ENABLE_HMIS_API'] == 'true'
    namespace :hmis, defaults: { format: :json } do
      devise_for :users, class_name: 'Hmis::User',
                         skip: [:registrations, :invitations, :passwords, :confirmations, :unlocks, :password_expired],
                         controllers: { sessions: 'hmis/sessions' },
                         path: '', path_names: { sign_in: 'login', sign_out: 'logout' }

      resource :user, only: [:show]
      resource :session_keepalive, only: [:create]

      devise_scope :hmis_user do
        match 'logout' => 'sessions#destroy', via: :get if Rails.env.development?
        if ENV['OKTA_DOMAIN'].present?
          get '/users/auth/okta/callback' => 'users/omniauth_callbacks#okta' if ENV['HMIS_OKTA_CLIENT_ID']
        end
      end

      get 'ac/prevention_assessment_report/:referral_id',
          to: 'reports#prevention_assessment_report',
          as: 'ac_prevention_assessment_report',
          defaults: { format: 'pdf' }
      get 'ac/consumer_summary_report',
          to: 'reports#consumer_summary_report',
          as: 'ac_consumer_summary_report',
          defaults: { format: 'pdf' }

      get 'theme', to: 'theme#index', defaults: { format: :json }
      get 'themes', to: 'theme#list', defaults: { format: :json }
      resource 'app_settings', only: [:show], defaults: { format: :json }
      resource 'impersonations', only: [:create, :destroy]

      post 'hmis-gql', to: 'graphql#execute', defaults: { schema: :hmis }
      mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/hmis/hmis-gql', defaults: { format: :html } if Rails.env.development?

      # Fall back to HMIS origin for any other `hmis/*` route.
      # We need this because the frontend proxies ALL requests to hmis/* to the backend.
      # Note: in a development environment, this ends up redirecting to the warehouse.
      get '*other', to: redirect { |_, req| req.origin || '404' }
    end

    namespace :hmis_admin do
      resources :access_overviews, only: [:index]
      resources :roles do
        patch :batch_update, on: :collection
      end
      resources :groups do
        get :entities, on: :member
        patch :bulk_entities, on: :member
      end
      resources :user_groups do
        resources :users, only: [:create, :destroy], controller: 'user_groups/users'
      end
      resources :access_controls
      resources :users, only: [:index, :edit, :update]
    end

    namespace :hmis_client do
      resources :clients, only: [:none] do
        resources :assessments, only: [:show]
        resources :services, only: [:show]
      end
    end
  end
end
