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
  devise_for :users, controllers: { invitations: 'users/invitations', sessions: 'users/sessions'}
  devise_scope :user do
    match 'active' => 'users/sessions#active', via: :get
    match 'timeout' => 'users/sessions#timeout', via: :get
  end

  def healthcare_routes
    namespace :health do
      resources :patient, only: [:index]
      resources :utilization, only: [:index]
      resources :appointments, only: [:index]
      resources :medications, only: [:index]
      resources :problems, only: [:index]
      resource :careplan, except: [:destroy] do
        get :self_sufficiency_assessment
        get :print
      end
      namespace :careplan do
        resources :goals do
          post :sort, on: :collection
          resources :previous, only: [:index, :show]
        end
        namespace :team do
          resources :members, only: [:index, :create, :destroy, :new] do
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
    resources :project_type_reconciliation, only: [:index]
    resources :missing_projects, only: [:index]
    resources :dob_entry_same, only: [:index]
    resources :non_alpha_names, only: [:index]
    resources :future_enrollments, only: [:index]
    resources :long_standing_clients, only: [:index]
    resources :really_old_enrollments, only: [:index]
    resources :service_after_exit, only: [:index]
    resources :entry_exit_service, only: [:index]
    resources :disabilities, only: [:index]
    resources :chronic, only: [:index] do
      get :summary, on: :collection
    end
    resources :chronic_housed, only: [:index]
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
    namespace :veteran_details do
      resources :exits, only: [:index]
      resources :entries, only: [:index]
      resources :actives, only: [:index]
    end
    resources :open_enrollments_no_service, only: [:index]
    resources :manage_cas_flags, only: [:index] do
      post :bulk_update, on: :collection
    end
    resources :find_by_id, only: [:index] do
      post :search, on: :collection
    end
    namespace :project do
      resource :data_quality do
        get :download, on: :member
      end
    end
    namespace :cas do
      resources :decision_efficiency, only: [:index] do
        collection do
          get :chart
        end
      end
      resources :decline_reason, only: [:index]
      resources :canceled_matches, only: [:index]
      resources :chronic_reconciliation, only: [:index] do
        collection do
          patch :update
        end
      end
    end
    namespace :health do
      resources :overview, only: [:index]
    end
  end

  resources :client_matches, only: [:index, :update] do
    post :defer, on: :collection
    post :defer, on: :member
  end
  resources :source_clients, only: [:edit, :update] do
    member do
      get :image
    end
  end
  resources :clients do
    member do
      # get :month_of_service
      get :service_range
      # get :history
      get :vispdat
      get :rollup
      get :assessment
      get :image
      get :chronic_days
      patch :merge
      patch :unmerge
      resource :cas_active, only: :update
    end
    resource :history, only: [:show], controller: 'clients/history'
    resource :month_of_service, only: [:show], controller: 'clients/month_of_service'
    resource :cas_readiness, only: [:edit, :update], controller: 'clients/cas_readiness'
    resource :chronic, only: [:edit, :update], controller: 'clients/chronic'
    resources :vispdats, controller: 'clients/vispdats'
    resources :files, controller: 'clients/files'
    resources :notes, only: [:destroy, :create], controller: 'clients/notes'
    resource :eto_api, only: [:show, :update], controller: 'clients/eto_api'
    resources :users, only: [:index, :create, :destroy], controller: 'clients/users'
    healthcare_routes()
  end

  namespace :window do
    resources :source_clients, only: [:edit, :update] do
      member do
        get :image
      end
    end
    resources :clients do
      resources :print, only: [:index]
      healthcare_routes()
      get :rollup
      get :assessment
      get :image
      resource :history, only: [:show], controller: 'clients/history'
      resource :month_of_service, only: [:show], controller: 'clients/month_of_service'
      resources :vispdats, controller: 'clients/vispdats'
      resources :files, controller: 'clients/files'
      resource :eto_api, only: [:show, :update], controller: 'clients/eto_api'
      resources :users, only: [:index, :create, :destroy], controller: 'clients/users'
    end
  end

  namespace :assigned do
    resources :clients, only: [:index]
  end

  resources :censuses, only: [:index] do
    get :date_range, on: :collection
    get :details, on: :collection
  end
  namespace :census do
    resources :project_types, only: [:index] do
      get :json, on: :collection
    end
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

  resources :cohorts, except: [:new] do
    resources :cohort_clients do
      resources :cohort_client_notes
    end
  end

  resources :imports do
    get :download, on: :member
  end
  resources :match_logs, only: [:index]
  resources :service_history_logs, only: [:index]
  resources :data_sources do
    resources :uploads, except: [:update, :destroy, :edit]
  end

  resources :organizations, only: [:index, :show] do
    resources :contacts, except: [:show], controller: 'organizations/contacts'
  end
  resources :projects, only: [:index, :show] do
    resources :contacts, except: [:show], controller: 'projects/contacts'
    resources :data_quality_reports, only: [:index, :show] do
      get :support, on: :member
    end
  end

  resources :project_groups, except: [:destroy, :show] do
    resources :contacts, except: [:show], controller: 'project_groups/contacts'
    resources :data_quality_reports, only: [:index, :show], controller: 'data_quality_reports_project_group' do
      get :support, on: :member
    end
  end

  resources :weather, only: [:index]

  resources :notifications, only: [:show] do
    resources :projects, only: [:show] do
      resources :data_quality_reports, only: [:show]
    end
    resources :project_groups, only: [:show] do
      resources :data_quality_reports, only: [:show], controller: 'data_quality_reports_project_group'
    end
  end

  namespace :api do
    namespace :health do
      namespace :claims do
        resources :patients, only: [] do
          resources :amount_paid, only: [:index], controller: 'patients/amount_paid'
          resources :claims_volume, only: [:index], controller: 'patients/claims_volume'
          resources :ed_nyu_severity, only: [:index], controller: 'patients/ed_nyu_severity'
          resources :roster, only: [:index], controller: 'patients/roster'
          resources :top_conditions, only: [:index], controller: 'patients/top_conditions'
          resources :top_ip_conditions, only: [:index], controller: 'patients/top_ip_conditions'
          resources :top_providers, only: [:index], controller: 'patients/top_providers'
        end
        resources :amount_paid, only: [:index]
        resources :claims_volume, only: [:index]
        resources :ed_nyu_severity, only: [:index]
        resources :roster, only: [:index]
        resources :top_conditions, only: [:index]
        resources :top_ip_conditions, only: [:index]
        resources :top_providers, only: [:index]
      end
    end
  end

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
    resources :translation_keys, only: [:index, :update]
    resources :translation_text, only: [:update]
    resources :configs, only: [:index] do
      patch :update, on: :collection
    end
    resources :data_quality_grades, only: [:index]
    resources :missing_grades, only: [:create, :update, :destroy]
    resources :utilization_grades, only: [:create, :update, :destroy]
    namespace :eto_api do
      resources :assessments, only: [:index, :update]
    end
  end
  resource :account, only: [:edit, :update]

  unless Rails.env.production?
    resource :style_guide, only: :none do
      get :careplan
      get :health_team
      get :icon_font
      get :add_goal
      get :add_team_member
    end
  end

  namespace :system_status do
    get :operational
  end
  root 'root#index'
end
