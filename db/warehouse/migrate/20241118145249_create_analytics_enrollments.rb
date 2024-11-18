class CreateAnalyticsEnrollments < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.enrollments"
  end
end
