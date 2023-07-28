BostonHmis::Application.routes.draw do
  resources :clients, only: [:none] do
    namespace :health_pctp do
      resources :careplans do
        resources :needs
        resources :goals
        resource :update_signature
        member do
          delete :remove_file
          get :download
          patch :upload
          get :new_pdf
        end
      end
    end
  end
end
