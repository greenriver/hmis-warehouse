BostonHmis::Application.routes.draw do
  scope module: :hud_lsa, path: :hud_reports, as: :hud_reports do
    resources :lsas do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      get :download_intermediate, on: :member
    end
  end
end
