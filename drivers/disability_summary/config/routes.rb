BostonHmis::Application.routes.draw do
  namespace :disability_summary do
    namespace :warehouse_reports do
      resources :disability_summary, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'disability_summary#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
      end
    end
  end
end
