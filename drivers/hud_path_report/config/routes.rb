BostonHmis::Application.routes.draw do
  scope module: :hud_path_report, path: :hud_reports, as: :hud_reports do
    resources :paths do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      resources :questions, only: [:show, :create] do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show
      end
    end
  end
end
