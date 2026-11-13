###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateCeCandidateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :ce_match_candidate_events do |t|
      t.references :candidate_pool, null: false, foreign_key: { to_table: :ce_match_candidate_pools }
      t.references :client_proxy, null: false, foreign_key: { to_table: :ce_client_proxies }
      t.jsonb :snapshot, null: false
      t.string :event_name, null: false
      t.datetime :created_at, null: false
    end
  end
end
