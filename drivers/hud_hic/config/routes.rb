BostonHmis::Application.routes.draw do
  scope module: :hud_hic, path: :hud_reports, as: :hud_reports do
    resources :hics do
      get :running, on: :collection
      get :running_all_questions, on: :collection
      get :history, on: :collection
      get :download, on: :member
      resources :questions, only: [:show, :create], controller: 'hic/questions' do
        get :result, on: :member
        get :running, on: :member
        resources :cells, only: :show, controller: 'hic/cells'
      end
    end
  end
end
