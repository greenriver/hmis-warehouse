class CreateAnalyticsLookupsYesNoEtcs < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.lookups_yes_no_etcs"
  end
end
