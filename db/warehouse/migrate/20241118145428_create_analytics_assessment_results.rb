class CreateAnalyticsAssessmentResults < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.assessment_results"
  end
end
