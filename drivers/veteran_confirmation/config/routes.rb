BostonHmis::Application.routes.draw do
  namespace :clients do
    resources :veteran_confirmations, only: [:show], controller: '/veteran_confirmation/veteran_confirmations'
  end
end
