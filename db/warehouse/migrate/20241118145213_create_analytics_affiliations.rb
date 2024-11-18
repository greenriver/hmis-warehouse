class CreateAnalyticsAffiliations < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.affiliations"
  end
end
