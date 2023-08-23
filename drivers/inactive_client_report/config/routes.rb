BostonHmis::Application.routes.draw do
  namespace :inactive_client_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index] do
        get :filters, on: :collection
        # get :download, on: :collection
      end
    end
  end
end
