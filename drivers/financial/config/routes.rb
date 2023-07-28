BostonHmis::Application.routes.draw do
  namespace :financial do
    resources :clients, only: [:show] do
      get 'rollup/:partial', to: 'clients#rollup', as: :rollup
    end
  end
end
