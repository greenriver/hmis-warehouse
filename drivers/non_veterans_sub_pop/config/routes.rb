Rails.application.routes.draw do
  sub_population = :non_veterans
  namespace :dashboards do
    resources sub_population, only: :index, controller: "/#{sub_population}_sub_pop/dashboards/#{sub_population}" do
      collection do
        get :active
        get :housed
        get :entered
        get 'section/:partial', to: "/#{sub_population}_sub_pop/dashboards/#{sub_population}#section", as: :section
      end
    end
  end
end
