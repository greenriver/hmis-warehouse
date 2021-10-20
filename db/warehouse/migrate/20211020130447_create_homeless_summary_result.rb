class CreateHomelessSummaryResult < ActiveRecord::Migration[5.2]
  def change
    create_table :homeless_summary_report_results do |t|
      t.references :report
      t.string :section
      t.string :household_category
      t.string :demographic_category
      t.string :characteristic
      t.string :calculation
      t.float :value
      t.string :format
      t.jsonb :details

      t.datetime :deleted_at
    end
  end
end
