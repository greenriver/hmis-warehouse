BostonHmis::Application.routes.draw do
  resources :data_sources, only: [:none] do
    namespace :hmis_supplemental do
      resources :data_sets do
        resource :upload, only: [:create, :new], controller: 'data_set_uploads'
      end
    end
  end
  namespace :hmis_supplemental do
    resources :data_sets, only: [:none] do
      resources :client_data_sets, only: [:show]
    end
  end
end
