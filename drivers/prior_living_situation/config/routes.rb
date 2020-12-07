BostonHmis::Application.routes.draw do
  namespace :prior_living_situation do
    namespace :warehouse_reports do
      resources :prior_living_situation, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'core#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
      end
    end
  end
end
