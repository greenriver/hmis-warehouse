BostonHmis::Application.routes.draw do
  namespace :hmis_external_apis do
    # TODO
    # get '/my_path', to: 'hmis_external_apis/my_controller'
    resources :referrals, only: [:create]
  end
end
