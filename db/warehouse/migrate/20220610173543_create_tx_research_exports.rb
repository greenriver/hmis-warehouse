class CreateTxResearchExports < ActiveRecord::Migration[6.1]
  def change
    create_table :tx_research_exports do |t|
      t.references :user, index: true
      t.references :export
      t.jsonb :options, default: {}
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :processing_errors
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
