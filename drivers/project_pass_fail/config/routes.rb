BostonHmis::Application.routes.draw do
  namespace :project_pass_fail do
    namespace :warehouse_reports do
      resources :project_pass_fail, only: [:index, :show, :destroy, :create] do
        resources :project, only: [:show]
        get 'section/:partial', on: :collection, to: 'project_pass_fail#section', as: :section
        get :filters, on: :collection
        get :download, on: :collection
      end
    end
  end
end
