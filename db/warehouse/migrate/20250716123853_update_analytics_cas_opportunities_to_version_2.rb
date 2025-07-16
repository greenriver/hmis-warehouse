class UpdateAnalyticsCasOpportunitiesToVersion2 < ActiveRecord::Migration[7.1]
  def change
    replace_view 'analytics.cas_opportunities', version: 2, revert_to_version: 1
  end
end
