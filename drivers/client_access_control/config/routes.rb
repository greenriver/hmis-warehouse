BostonHmis::Application.routes.draw do
  resources :clients, only: [:index], controller: 'client_access_control/clients'
end
