BostonHmis::Application.routes.draw do
  namespace :custom_imports_boston_assessment_lookups do
    resources :files, only: [:show]
  end
end
