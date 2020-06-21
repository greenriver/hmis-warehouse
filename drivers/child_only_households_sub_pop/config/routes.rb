Rails.application.routes.draw do
  namespace :dashboards do
    resources :child_only_households, only: :index, controller:  '/child_only_households_sub_pop/dashboards/child_only_households' do
      collection do
        get :active
        get :housed
        get :entered
        get 'section/:partial', to: '/child_only_households_sub_pop/dashboards/child_only_households#section', as: :section
      end
    end
  end
end
