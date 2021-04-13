BostonHmis::Application.routes.draw do
  namespace :public_reports do
    namespace :warehouse_reports do
      resources :point_in_time do
        get :raw, on: :member
      end
      resources :pit_by_month do
        get :raw, on: :member
      end
      resources :number_housed do
        get :raw, on: :member
      end
      resources :homeless_count do
        get :raw, on: :member
      end
      resources :homeless_count_comparison do
        get :raw, on: :member
      end
      resources :homeless_populations do
        get :raw, on: :member
        get :overall, on: :member
        get :housed, on: :member
        get :individuals, on: :member
        get :adults_with_children, on: :member
        get :veterans, on: :member
      end
      resources :public_configs, only: [:index, :create]
    end
  end
end
