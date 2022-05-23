BostonHmis::Application.routes.draw do
  namespace :longitudinal_spm do
    namespace :warehouse_reports do
      resources :reports, only: [:index, :create, :show, :destroy] do
        get :history, on: :collection
        get :details
      end
    end
  end
end
