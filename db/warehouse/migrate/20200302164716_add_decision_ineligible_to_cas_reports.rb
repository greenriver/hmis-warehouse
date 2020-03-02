class AddDecisionIneligibleToCasReports < ActiveRecord::Migration[5.2]
  def change
    add_column :cas_reports, :ineligible_in_warehouse, :boolean, default: false, null: false, index: true
  end
end
