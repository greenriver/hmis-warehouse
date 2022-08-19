BostonHmis::Application.routes.draw do
  namespace :ce_performance do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get :details, on: :member
        get :clients, on: :member
      end
      resources :goal_configs, except: [:show]
    end
  end
end
