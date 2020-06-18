BostonHmis::Application.routes.draw do
  scope :hmis_csv_twenty_twenty do
    resources :loads
  end
  # TODO
  # get '/my_path', to: 'hmis_csv_twenty_twenty/my_controller'
end
