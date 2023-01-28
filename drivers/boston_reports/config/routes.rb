BostonHmis::Application.routes.draw do
  namespace :boston_reports do
    namespace :warehouse_reports do
      resources :street_to_home do
        get :details, on: :member
      end
    end
  end
end
