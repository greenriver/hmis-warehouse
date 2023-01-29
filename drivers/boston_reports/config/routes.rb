BostonHmis::Application.routes.draw do
  namespace :boston_reports do
    namespace :warehouse_reports do
      resources :street_to_homes, only: [:index] do
        get :details, on: :collection
        get 'section/:partial', on: :collection, to: 'core#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
        post :render_section, on: :collection
      end
    end
  end
end
