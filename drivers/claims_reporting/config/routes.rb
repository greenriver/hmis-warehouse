BostonHmis::Application.routes.draw do
  namespace :claims_reporting do
    resources :claims
  end
end
