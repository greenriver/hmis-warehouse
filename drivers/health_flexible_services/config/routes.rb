BostonHmis::Application.routes.draw do
  resources :clients do
    namespace :health_flexible_services do
      resources :vprs
    end
  end
end
