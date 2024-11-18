class CreateAnalyticsEmploymentEducations < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.employment_educations'
  end
end
