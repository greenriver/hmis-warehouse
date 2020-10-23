Rails.application.routes.draw do
  namespace :project_scorecard do
    namespace :warehouse_reports do
      resource :scorecards
    end
  end
end
