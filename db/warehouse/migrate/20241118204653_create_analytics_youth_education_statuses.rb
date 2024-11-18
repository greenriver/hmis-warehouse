class CreateAnalyticsYouthEducationStatuses < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.youth_education_statuses"
  end
end
