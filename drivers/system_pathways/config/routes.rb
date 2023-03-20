BostonHmis::Application.routes.draw do
  namespace :system_pathway do
    namespace :warehouse_reports do
      resources :reports do
        get :details, on: :member
      end
    end
  end
end
