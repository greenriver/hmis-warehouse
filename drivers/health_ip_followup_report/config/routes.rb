BostonHmis::Application.routes.draw do
  namespace :health_ip_followup_report do
    namespace :warehouse_reports do
      resources :followup_reports, only: [:index]
    end
  end
end
