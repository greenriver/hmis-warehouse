BostonHmis::Application.routes.draw do
  resources :clients, only: [:index, :show], controller: 'client_access_control/clients' do
    member do
      get :appropriate
      get :simple
      get :image
      get :enrollment_details
      resource :history, only: [:show], controller: 'client_access_control/history' do
        get :pdf, on: :collection
        post :queue, on: :collection
      end
    end
  end
end
