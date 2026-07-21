###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

OpenPath::Application.routes.draw do
  get 'hmis/system_status/operational', to: 'system_status#operational'
  get 'hmis/system_status/cache_status', to: 'system_status#cache_status'
  get 'hmis/system_status/details', to: 'system_status#details'
  get 'hmis/system_status/ping', to: 'system_status#ping'
  get 'hmis/system_status/exception', to: 'system_status#exception'

  # Routes for the HMIS API
  if ENV['ENABLE_HMIS_API'] == 'true'
    namespace :hmis, defaults: { format: :json } do
      # AUTH_METHOD seam: Hmis::User's `devise` macro is gated off under JWT, so an ungated
      # devise_for/devise_scope raises at route-draw and aborts the whole JWT boot. Gate the HMIS
      # Devise auth surface so the app boots. Under JWT the always-on HMIS routes below (resource
      # :user, session_keepalive, hmis-gql, impersonations) authenticate off the forwarded JWT via
      # Hmis::Concerns::JwtHmisCurrentUser; login is served by oauth2-proxy itself (external IdP
      # contract), so there's no replacement Devise login route. Logout still needs a same-origin
      # endpoint for the SPA's fetch-based logoutUser() to hit — see the AuthMethod.jwt? route below,
      # defined outside this namespace (like devise_for, it needs to escape the enclosing
      # `namespace :hmis`'s automatic route-name prefixing to share Devise's exact helper name).
      if AuthMethod.devise?
        devise_for :users, class_name: 'Hmis::User',
                           skip: [:registrations, :invitations, :passwords, :confirmations, :unlocks, :password_expired],
                           controllers: { sessions: 'hmis/sessions' },
                           path: '', path_names: { sign_in: 'login', sign_out: 'logout' }
      end

      resource :user, only: [:show]
      # :show (GET) is what the frontend actually polls with, since it sends credentials: 'include'
      # with no CSRF header; :create (POST) is kept for any existing caller expecting the old verb.
      resource :session_keepalive, only: [:create, :show]

      if AuthMethod.devise?
        devise_scope :hmis_user do
          match 'logout' => 'sessions#destroy', via: :get if Rails.env.development?
          if ENV['OKTA_DOMAIN'].present?
            get '/users/auth/okta/callback' => 'users/omniauth_callbacks#okta' if ENV['HMIS_OKTA_CLIENT_ID']
          end
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

      get 'clients/:client_id/files/:id', to: 'client_files#show', as: :client_file

      # Fall back to HMIS origin for any other `hmis/*` route.
      # We need this because the frontend proxies ALL requests to hmis/* to the backend.
      # Note: in a development environment, this ends up redirecting to the warehouse.
      get '*other', to: redirect { |_, req| req.origin || '404' }
    end

    # Defined outside the `namespace :hmis` block (like Idp::SessionsController's routes at the top
    # of this file) so it shares Devise's exact `destroy_hmis_user_session_path` helper name rather
    # than being auto-prefixed to `hmis_destroy_hmis_user_session_path` by the enclosing namespace.
    delete 'hmis/logout', to: 'hmis/idp/sessions#destroy', as: 'destroy_hmis_user_session', defaults: { format: :json } unless AuthMethod.devise?

    namespace :hmis_admin do
      resources :access_overviews, only: [:index]
      resources :roles do
        resource :audit, only: :show, controller: 'role_audits' do
          get :export, on: :member
        end
        patch :batch_update, on: :collection
      end
      resources :groups do
        resource :audit, only: :show, controller: 'group_audits' do
          get :export, on: :member
        end
        get :entities, on: :member
        patch :bulk_entities, on: :member
      end
      resources :user_groups do
        resource :audit, only: :show, controller: 'user_group_audits' do
          get :export, on: :member
        end
        resources :users, only: [:create, :destroy], controller: 'user_groups/users'
      end
      resources :access_controls do
        resource :audit, only: :show, controller: 'access_control_audits' do
          get :export, on: :member
        end
        get :audits, on: :collection
        post :render_audits, on: :collection
      end
      resources :users, only: [:index, :edit, :update]
      resources :project_groups, only: [:index, :new, :create, :edit, :update, :show, :destroy]
    end

    namespace :hmis_client do
      resources :clients, only: [:none] do
        resources :assessments, only: [:show]
        resources :services, only: [:show]
      end
    end
  end
end
