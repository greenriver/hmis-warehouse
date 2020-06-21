Rails.application.routes.draw do
  namespace :dashboards do
    resources :adult_only_households, only: :index, controller:  '/adult_only_households_sub_pop/dashboards/adult_only_households' do
      collection do
        get :active
        get :housed
        get :entered
        get 'section/:partial', to: '/adult_only_households_sub_pop/dashboards/adult_only_households#section', as: :section
      end
    end
  end
end
