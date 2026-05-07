# frozen_string_literal: true

class AddHmisClientSearchQuery < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :hmis_client_search_queries, id: :uuid do |t|
      t.timestamps
      t.references :created_by, null: false, index: false
      t.references :data_source, null: false, index: false
      t.jsonb :params, null: false
      t.string :fingerprint, null: false, comment: 'hash of normalized search parameters used for deduplication and efficient query retrieval'
    end
    add_index :hmis_client_search_queries, [:data_source_id, :created_by_id, :fingerprint], name: 'uidx_hmis_client_search_queries', unique: true
  end
end
