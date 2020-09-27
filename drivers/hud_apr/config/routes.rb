BostonHmis::Application.routes.draw do
  scope module: :hud_apr, path: :hud_reports, as: :hud_reports do
    resources :aprs do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      resources :questions, only: [:show, :update] do
        get :result, on: :member
        get :running, on: :member
      end
    end
  end
end
