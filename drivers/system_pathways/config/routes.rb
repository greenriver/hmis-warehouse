BostonHmis::Application.routes.draw do
  namespace :system_pathways do
    namespace :warehouse_reports do
      resources :reports do
        get :details, on: :member
        get 'chart_data/:chart', to: 'reports#chart_data', on: :member, as: :chart_data
      end
    end
  end
end
