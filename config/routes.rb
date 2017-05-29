Rails.application.routes.draw do
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unacceptable", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  mount LetsencryptPlugin::Engine, at: '/'
  class OnlyXhrRequest
    def matches?(request)
      request.xhr?
    end
  end
  devise_for :users, controllers: { invitations: 'users/invitations'}

  def healthcare_routes
    namespace :health do
      resources :patient, only: [:index]
      resources :utilization, only: [:index]
      resources :appointments, only: [:index]
      resources :medications, only: [:index]
      resources :problems, only: [:index]
      namespace :careplan do
        resources :goals
        namespace :team do
          resources :members, only: [:index, :create, :destroy] do
            get :previous, on: :collection
            post :restore
          end
        end
      end
    end
  end

  resources :reports do
    resources :report_results, path: 'results', only: [:index, :show, :create, :update, :destroy] do

      resources :support, only: [:index], controller: 'report_results/support'

    end
  end
  namespace :reports do
    namespace :hic do
      resource :export, only: [:show]
      resource :organization, only: [:show]
      resource :project, only: [:show]
      resource :inventory, only: [:show]
      resource :site, only: [:show]
    end
  end
  resources :report_results_summary, only: [:show]
  resources :warehouse_reports, only: [:index]
  namespace :warehouse_reports do
    resources :missing_projects, only: [:index]
    resources :dob_entry_same, only: [:index]
    resources :non_alpha_names, only: [:index]
    resources :future_enrollments, only: [:index]
    resources :long_standing_clients, only: [:index]
    resources :really_old_enrollments, only: [:index]
    resources :service_after_exit, only: [:index]
    resources :entry_exit_service, only: [:index]
    resources :chronic, only: [:index] do
      get :summary, on: :collection
    end
    resources :first_time_homeless, only: [:index] do
      get :summary, on: :collection
    end
    resources :client_in_project_during_date_range, only: [:index]
    resources :bed_utilization, only: [:index]
    resources :length_of_stay, only: [:index] do
      collection do
        get :fetch_length
      end
    end
    resources :missing_values, only: [:index]
    resources :active_veterans, only: [:index]
    resources :open_enrollments_no_service, only: [:index]
    resources :manage_cas_flags, only: [:index] do
      post :bulk_update, on: :collection
    end
    resources :find_by_id, only: [:index] do
      post :search, on: :collection
    end
  end

  resources :client_matches, only: [:index, :update] do
    post :defer, on: :collection
    post :defer, on: :member
  end
  resources :clients, only: [:index, :show, :edit, :update] do
    member do
      get :month_of_service
      get :service_range
      get :history
      get :rollup
      get :assessment
      get :image
      get :chronic_days
      patch :merge
      patch :unmerge
    end
    healthcare_routes()
  end

  namespace :window do
    resources :clients, only: [:index, :show] do
      resources :print, only: [:index]
      resources :youth, only: [:index]
      healthcare_routes()
    end
  end

  resources :censuses, only: [:index] do
    get :date_range, on: :collection
    get :details, on: :collection
  end
  resources :dashboards, only: [:index]
  namespace :dashboards do
    resources :veterans, only: [:index] do
      collection do
        get :active
        get :housed
        get :entered
      end
    end
    resources :clients, only: [:index] do
      collection do
        get :active
        get :housed
        get :entered
      end
    end
  end

  resources :imports
  resources :match_logs, only: [:index]
  resources :service_history_logs, only: [:index]
  resources :data_sources do
    resources :uploads, except: [:update, :destroy, :edit]
  end

  resources :organizations, only: [:index, :show]
  resources :projects, only: [:index, :show]
  resources :weather, only: [:index]

  namespace :admin do
    # resolves route clash w/ devise
    resources :users, except: [:show, :new, :create] do
      resource :resend_invitation, only: :create
      resource :recreate_invitation, only: :create
      resource :audit, only: :show
    end
    resources :roles
    namespace :dashboard do
      resources :imports, only: [:index]
      resources :debug, only: [:index]
    end
    namespace :health do
      resources :admin, only: [:index]
      resources :patients, only: [:index] do
        post :update, on: :collection
      end
      resources :users, only: [:index] do
        post :update, on: :collection
      end
      resources :roles, only: [:index]
    end
  end
  resource :account, only: [:edit, :update]

  root 'root#index'
end
