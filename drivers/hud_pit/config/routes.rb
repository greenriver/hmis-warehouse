BostonHmis::Application.routes.draw do
  scope module: :hud_pit, path: :hud_reports, as: :hud_reports do
    resources :pits do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      resources :questions, only: [:show, :create] do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show
      end
    end
  end
end
