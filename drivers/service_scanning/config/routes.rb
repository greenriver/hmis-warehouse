Rails.application.routes.draw do
  namespace :service_scanning do
    resources :services
    resources :scanner_ids
  end
end
