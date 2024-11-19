class CreateAnalyticsLookupsFundingSources < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.lookups_funding_sources'
  end
end
