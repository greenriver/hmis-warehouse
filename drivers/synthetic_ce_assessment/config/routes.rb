BostonHmis::Application.routes.draw do
  namespace :synthetic_ce_assessments do
    resources :project_config, only: [:new, :edit, :update]
  end
end
