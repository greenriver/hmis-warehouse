# frozen_string_literal: true

class CreateClientSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :client_search_queries do |t|
      t.references :user, null: false, index: false
      t.jsonb :params, null: false
      t.string :fingerprint, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :client_search_queries, [:user_id, :fingerprint], name: 'uidx_client_search_queries', unique: true
  end
end
