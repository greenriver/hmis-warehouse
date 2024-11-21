class CreateAnalyticsChEnrollments < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.ch_enrollments'
  end
end
