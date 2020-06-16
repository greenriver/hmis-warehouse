Rails.application.routes.draw do
  namespace :dashboards do
    resources :youth_parents, only: :index, controller:  '/youth_parents_sub_pop/dashboards/youth_parents' do
      collection do
        get :active
        get :housed
        get :entered
        get 'section/:partial', to: '/youth_parents_sub_pop/dashboards/youth_parents#section', as: :section
      end
    end
  end
end
