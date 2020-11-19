BostonHmis::Application.routes.draw do
  resources :clients do
    namespace :health_flexible_service do
      resources :vprs
    end
  end

  namespace :health_flexible_service do
    namespace :warehouse_reports do
      resources :member_lists, only: [:index, :create]
    end
  end
end
