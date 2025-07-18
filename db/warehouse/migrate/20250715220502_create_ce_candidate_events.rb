# frozen_string_literal: true

class CreateCeCandidateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :ce_match_candidate_events do |t|
      t.references :candidate_pool, null: false, foreign_key: { to_table: :ce_match_candidate_pools }
      t.references :client_proxy, null: false
      t.jsonb :snapshot, null: false
      t.string :event_name, null: false
      t.datetime :created_at, null: false
    end
  end
end
