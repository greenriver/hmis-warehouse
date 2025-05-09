# frozen_string_literal: true

class CreateClientSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :client_search_queries do |t|
      t.timestamps
      t.references :created_by, null: false, index: false
      t.jsonb :params, null: false
      t.string :fingerprint, null: false
    end
    add_index :client_search_queries, :fingerprint, name: 'uidx_client_search_queries', unique: true
  end
end
