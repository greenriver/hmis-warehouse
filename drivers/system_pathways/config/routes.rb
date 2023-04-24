BostonHmis::Application.routes.draw do
  namespace :system_pathways do
    namespace :warehouse_reports do
      resources :reports do
        get :details, on: :member
        get 'section/:section', to: 'reports#section', on: :member, as: :section
      end
    end
  end
end
