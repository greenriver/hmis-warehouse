BostonHmis::Application.routes.draw do
  namespace :hmis_data_quality_tool do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get :clients, on: :member
      end
    end
  end
end
