BostonHmis::Application.routes.draw do
  scope :client_documents_report do
    # TODO
    # get '/my_path', to: 'client_documents_report/my_controller'
  end
  namespace :client_documents_report do
    namespace :warehouse_reports do
      resources :reports, only: [:index] do
        get :filters, on: :collection
      end
    end
  end
end
