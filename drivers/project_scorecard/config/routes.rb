Rails.application.routes.draw do
  namespace :project_scorecard do
    namespace :warehouse_reports do
      resources :scorecards, only: [:index, :create, :show, :edit, :update] do
        get :for_project, on: :collection
        get :for_group, on: :collection
      end
    end
  end
end
