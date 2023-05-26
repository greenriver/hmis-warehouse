BostonHmis::Application.routes.draw do
  resources :clients, only: [:none] do
    namespace :health_thrive_assessment do
      resources :assessments
    end
  end
end
