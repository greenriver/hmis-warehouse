BostonHmis::Application.routes.draw do
  namespace :performance_measurement do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get :details, on: :member
      end
    end
  end
end
