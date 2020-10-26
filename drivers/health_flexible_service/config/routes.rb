BostonHmis::Application.routes.draw do
  resources :clients do
    namespace :health_flexible_service do
      resources :vprs
    end
  end
end
