class CreateAnalyticsCustomAssessments < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.custom_assessments"
  end
end
