BostonHmis::Application.routes.draw do
  namespace :custom_imports_boston_contacts do
    resources :files, only: [:show]
  end
end
