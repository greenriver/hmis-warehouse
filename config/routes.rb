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
      resources :patient, only: [:index, :update]
      resources :utilization, only: [:index]
      resources :appointments, only: [:index]
      resources :medications, only: [:index]
      resources :problems, only: [:index]
      resources :self_sufficiency_matrix_forms
      resources :sdh_case_management_notes, only: [:show, :new, :create, :edit, :update, :destroy] do
        member do
          delete :remove_file
          get :download
        end
      end
      resources :services
      resources :qualifying_activities, only: [:index]
      resources :durable_equipments, except: [:index]
      resources :files, only: [:index, :show]
      resources :team_members, controller: :patient_team_members
      resources :careplans, except: [:create] do
        resources :team_members, except: [:index, :show]
        resources :goals, except: [:index, :show]
        get :self_sufficiency_assessment
        get :print
        get :revise, on: :member
      end
      resources :participation_forms do
        member do
          delete :remove_file
          get :download
        end
      end
      resources :release_forms do
        member do
          delete :remove_file
          get :download
        end
      end
      resources :comprehensive_health_assessments, path: :chas, as: :chas do
        member do
          delete :remove_file
          get :download
          patch :upload
        end
      end
      namespace :pilot do
        resources :patient, only: [:index]
        resources :metrics, only: [:index]
        resource :careplan, except: [:destroy] do
          get :self_sufficiency_assessment
          get :print
        end
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

  def sub_populations
    [
      :childrens,
      :clients,
      :families,
      :individual_adults,
      :non_veterans,
      :parenting_childrens,
      :parenting_youths,
      :veterans,
      :youths,
    ].freeze
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
  namespace :hud_reports do
    namespace :ahar do
      namespace :fy_2017 do
        resources :base, only: [:create]
        resources :data_source, only: [:create]
        resources :project, only: [:create]
        resources :veteran, only: [:create]
        get :support
      end
    end
  end
  resources :report_results_summary, only: [:show]
  resources :warehouse_reports, only: [:index] do
    resources :support, only: [:index], controller: 'warehouse_reports/support'
  end
  namespace :warehouse_reports do
    resources :project_type_reconciliation, only: [:index]
    resources :missing_projects, only: [:index]
    resources :dob_entry_same, only: [:index]
    resources :non_alpha_names, only: [:index]
    resources :future_enrollments, only: [:index]
    resources :long_standing_clients, only: [:index]
    resources :really_old_enrollments, only: [:index]
    resources :entry_exit_service, only: [:index]
    resources :recidivism, only: [:index]
    resources :expiring_consent, only: [:index]
    resources :consent, only: [:index] do
      post :update_clients, on: :collection
    end
    resources :anomalies, only: [:index]
    resources :touch_point_exports, only: [:index] do
      collection do
        get :download
      end
    end
    resources :confidential_touch_point_exports, only: [:index] do
      collection do
        get :download
      end
    end
    resources :hmis_exports, except: [:edit, :update, :new] do
      collection do
        get :running
      end
    end
    resources :initiatives, except: [:edit, :update, :new] do
      get '(/:token)', controller: 'initiatives', action: :show, on: :member
      collection do
        get :running
      end
    end
    resources :disabilities, only: [:index, :show] do
      collection do
        get :summary
        get :running
      end
    end
    resources :chronic, only: [:index, :show, :destroy] do
      get :summary, on: :collection
      get :running, on: :collection
    end
    resources :hud_chronics, only: [:index, :show] do
      collection do
        get :summary
        get :running
      end
    end
    resources :active_veterans, only: [:index, :show] do
      collection do
        get :summary
        get :running
      end
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
    namespace :client_details do
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
      get :service_range
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
    resource :cas_readiness, only: [:edit, :update], controller: 'clients/cas_readiness'
    resource :chronic, only: [:edit, :update], controller: 'clients/chronic'
    resources :vispdats, controller: 'clients/vispdats' do
      member do
        put :add_child
          delete :remove_child
          put :upload_file
          delete :destroy_file
      end
    end
    resources :files, controller: 'clients/files' do
      get :preview, on: :member
      get :thumb, on: :member
      get :has_thumb, on: :member
      post :batch_download, on: :collection
    end
    resources :notes, only: [:index, :destroy, :create], controller: 'clients/notes'
    resource :eto_api, only: [:show, :update], controller: 'clients/eto_api'
    resources :users, only: [:index, :create, :update, :destroy], controller: 'clients/users'
    resources :anomalies, except: [:show], controller: 'clients/anomalies'
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
      resource :history, only: [:show], controller: 'clients/history' do
        get :pdf, on: :collection
      end
      resources :vispdats, controller: 'clients/vispdats' do
        member do
          put :add_child
          delete :remove_child
          put :upload_file
          delete :destroy_file
        end
      end
      resources :files, controller: 'clients/files' do
        get :preview, on: :member
        get :thumb, on: :member
        get :has_thumb, on: :member
        post :batch_download, on: :collection
      end
      resources :notes, only: [:index, :create, :destroy], controller: 'clients/notes'
      resource :eto_api, only: [:show, :update], controller: 'clients/eto_api'
      resources :users, only: [:index, :create, :update, :destroy], controller: 'clients/users'
    end
  end

  namespace :assigned do
    resources :clients, only: [:index]
  end
  namespace :expired do
    resources :clients, only: :index
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
    sub_populations.each do |sub_population|
      resources(sub_population, only: [:index]) do
        collection do
          get :active
          get :housed
          get :entered
        end
      end
    end
  end

  resources :cohorts, except: [:new] do
    resource :columns, only: [:edit, :update], controller: 'cohorts/columns'
    resources :cohort_clients, controller: 'cohorts/clients' do
      get :pre_destroy, on: :member
      get :field, on: :member
      patch :re_rank, on: :collection
      resources :cohort_client_notes, controller: 'cohorts/notes'
    end
    resource :report, on: :member, only: [:show], controller: 'cohorts/reports'
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

  resources :messages, only: [:show, :index] do
    collection do
      get :poll
      post :seen
    end
  end

  namespace :health do
    resources :patients, only: [:index]
    resources :my_patients, only: [:index]
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
      resources :agencies, except: [:show]
      resources :team_coordinators, only: [:index, :create, :destroy]
      resources :patients, only: [:index] do
        post :update, on: :collection
      end
      resources :patient_referrals, only: [:create] do
        patch :reject
        collection do
          get :review
          get :assigned
          get :rejected
          post :bulk_assign_agency
        end
        post :assign_agency
      end
      resources :agency_patient_referrals, only: [:create, :update] do
        collection do
          get :review
          get :reviewed
        end
      end
      resources :users, only: [:index] do
        post :update, on: :collection
        resources :agency_users, only: [:new, :edit, :create, :update]
      end
      resources :roles, only: [:index, :edit, :update]
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
      resources :assessments, only: [:index, :edit, :update]
    end
    resources :available_file_tags, only: [:index, :new, :create, :destroy]
    resources :administrative_events, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :public_files, only: [:index, :create, :destroy]
  end
  resource :account, only: [:edit, :update]
  resources :public_files, only: [:show]

  unless Rails.env.production?
    resource :style_guide, only: :none do
      get :careplan
      get :health_team
      get :icon_font
      get :add_goal
      get :add_team_member
      get :alerts
      get :tags
      get :client_dashboard
      get :buttons
      get :pagination
    end
  end

  namespace :system_status do
    get :operational
    get :cache_status
  end
  root 'root#index'
end
