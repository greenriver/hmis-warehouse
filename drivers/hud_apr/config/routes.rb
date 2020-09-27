BostonHmis::Application.routes.draw do
  scope module: :hud_apr, path: :hud_reports, as: :hud_reports do
    resources :aprs do
      resources :questions, only: [:show, :update] do
        get :result, on: :member
      end
    end
  end
end
