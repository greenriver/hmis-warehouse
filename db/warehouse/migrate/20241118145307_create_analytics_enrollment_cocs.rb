class CreateAnalyticsEnrollmentCocs < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.enrollment_cocs'
  end
end
