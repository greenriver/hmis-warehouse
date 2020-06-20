Rails.application.routes.draw do
  namespace :dashboards do
    resources :adults_with_children, only: :index, controller:  '/adults_with_children_sub_pop/dashboards/adults_with_children' do
      collection do
        get :active
        get :housed
        get :entered
        get 'section/:partial', to: '/adults_with_children_sub_pop/dashboards/adults_with_children#section', as: :section
      end
    end
  end
end
