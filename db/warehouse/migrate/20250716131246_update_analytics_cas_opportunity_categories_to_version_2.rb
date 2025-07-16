class UpdateAnalyticsCasOpportunityCategoriesToVersion2 < ActiveRecord::Migration[7.1]
  def change
    update_view "analytics.cas_opportunity_categories", version: 2, revert_to_version: 1
  end
end
