class CreateAnalyticsOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.organizations"
  end
end
