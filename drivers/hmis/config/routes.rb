BostonHmis::Application.routes.draw do
  # Routes for the HMIS API
  # NOTE: current omniauthable setup doesn't play nicely with multiple models.
  # If we need to use Okta and the HMIS API together, see https://stackoverflow.com/a/13591797
  if ENV['ENABLE_HMIS_API'] == 'true' && !ENV['OKTA_DOMAIN'].present?
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

      post 'hmis-gql', to: 'graphql#execute', defaults: { schema: :hmis }
      mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/hmis/hmis-gql', defaults: { format: :html } if Rails.env.development?
    end
    namespace :hmis_admin do
      resources :roles do
        resources :users, only: [:create, :destroy], controller: 'roles/users'
      end
      resources :groups do
        resources :users, only: [:create, :destroy], controller: 'groups/users'
      end
    end
  end
end
