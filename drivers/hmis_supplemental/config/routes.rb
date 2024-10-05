BostonHmis::Application.routes.draw do
  # scope '/admin', as: 'admin' do
  scope '/admin' do
    namespace :hmis_supplemental do
      resources :data_sets
    end
  end
  namespace :hmis_supplemental do
    resources :data_sets, only: [:none] do
      resources :client_data_sets, only: [:show]
    end
  end
end
