BostonHmis::Application.routes.draw do
  resources :clients, only: [:none] do
    namespace :health_pctp do
      resources :careplans do
        resources :needs
      end
    end
  end
end
