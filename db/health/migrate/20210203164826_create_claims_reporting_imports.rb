class CreateClaimsReportingImports < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_imports do |t|
      t.string :source_url, null: false
      t.string :source_hash, null: false, description: 'Digest::SHA256.hexdigest(content)'
      t.string :status_message
      t.datetime :started_at
      t.datetime :completed_at
      t.string :importer
      t.string :method
      t.jsonb :args
      t.jsonb :env
      t.jsonb :results
      t.binary :content
      t.timestamps
    end
  end
end
