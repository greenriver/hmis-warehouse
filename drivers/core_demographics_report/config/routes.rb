Rails.application.routes.draw do
  namespace :core_demographics_report do
    namespace :warehouse_reports do
      resources :core, only: [:index] do
        get :detail, on: :collection
      end
    end
  end
end
