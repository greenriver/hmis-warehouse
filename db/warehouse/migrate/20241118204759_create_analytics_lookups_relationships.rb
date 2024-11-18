class CreateAnalyticsLookupsRelationships < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.lookups_relationships"
  end
end
