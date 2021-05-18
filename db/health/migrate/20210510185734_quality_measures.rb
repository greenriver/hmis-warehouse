class QualityMeasures < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_quality_measures do |t|
      t.references :user, null: false
      t.jsonb :options
      t.jsonb :results
      t.string :processing_errors
      t.datetime :completed_at
      t.datetime :started_at
      t.datetime :failed_at
      t.datetime :deleted_at
      t.timestamps null: false
    end
  end
end
