BostonHmis::Application.routes.draw do
  namespace :system_pathways do
    namespace :warehouse_reports do
      resources :reports do
        get :details, on: :member
      end
    end
  end
end
