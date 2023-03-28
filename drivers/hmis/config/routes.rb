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
      end

      get 'theme', to: 'theme#index', defaults: { format: :json }
      get 'themes', to: 'theme#list', defaults: { format: :json }
      resource 'app_settings', only: [:show], defaults: { format: :json }

      post 'hmis-gql', to: 'graphql#execute', defaults: { schema: :hmis }
      mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/hmis/hmis-gql', defaults: { format: :html } if Rails.env.development?
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
