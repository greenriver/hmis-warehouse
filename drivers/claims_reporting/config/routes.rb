BostonHmis::Application.routes.draw do
  namespace :claims_reporting do
    namespace :warehouse_reports do
      resources :reconciliation, only: [:index, :create] do
      end
    end
  end
end
