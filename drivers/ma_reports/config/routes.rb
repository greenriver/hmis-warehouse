BostonHmis::Application.routes.draw do
  scope :ma_reports do
    namespace :warehouse_reports do
      resources :monthly_project_utilizations do
        get :details, on: :member
      end
    end
  end
end
