class AddMissingDeletedAtsToCeAprTables < ActiveRecord::Migration[5.2]
  def change
    change_table :hud_report_apr_ce_assessments do |t|
      t.datetime :deleted_at, index: true
    end
    change_table :hud_report_apr_ce_events do |t|
      t.datetime :deleted_at, index: true
    end
  end
end
