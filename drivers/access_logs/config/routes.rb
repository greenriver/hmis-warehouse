BostonHmis::Application.routes.draw do
  scope :access_log do
    # TODO
    # get '/my_path', to: 'access_logs/my_controller'
  end
  namespace :access_logs do
    namespace :warehouse_reports do
      resources :reports, only: [:index]
    end
  end
end
