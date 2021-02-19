class CreateClaimsReportingImports < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_imports do |t|
      t.string :source_url, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.boolean :successful
      t.string :status_message
      t.string :content_hash, description: 'Digest::SHA256.hexdigest(content)'
      t.binary :content
      t.string :importer
      t.string :method
      t.jsonb :args
      t.jsonb :env
      t.jsonb :results
      t.timestamps
    end
  end
end
