class CreateReportResultsSummaryTable < ActiveRecord::Migration
  def change
    create_table :report_results_summaries do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.timestamps null: false
      t.integer :weight, null: false, default: 0
    end
    add_reference :reports, :report_results_summary, index: true, foreign_key: true
  end
end
