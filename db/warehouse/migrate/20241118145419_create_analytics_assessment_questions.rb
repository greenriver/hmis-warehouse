class CreateAnalyticsAssessmentQuestions < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.assessment_questions'
  end
end
