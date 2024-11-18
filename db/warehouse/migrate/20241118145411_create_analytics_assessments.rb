class CreateAnalyticsAssessments < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.assessments"
  end
end
