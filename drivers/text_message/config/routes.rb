BostonHmis::Application.routes.draw do
  namespace :text_message do
    namespace :warehouse_reports do
      resources :queue, only: [:index]
    end
  end
end
