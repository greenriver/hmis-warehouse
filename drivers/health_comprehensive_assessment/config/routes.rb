BostonHmis::Application.routes.draw do
  resources :clients, only: [:none] do
    namespace :health_comprehensive_assessment do
      resources :assessments do
        resources :medications
        resources :sud_treatments
      end
    end
  end
end
