BostonHmis::Application.routes.draw do
  scope module: :hud_data_quality_report, path: :hud_reports, as: :hud_reports do
    resources :dqs do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      resources :questions, only: [:show, :create] do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show
      end
    end
  end
end
