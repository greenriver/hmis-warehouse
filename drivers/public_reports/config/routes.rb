BostonHmis::Application.routes.draw do
  namespace :public_reports do
    namespace :warehouse_reports do
      resources :point_in_time do
        get :raw, on: :member
      end
      resources :public_configs, only: [:index, :create]
    end
  end
end
