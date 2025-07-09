###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCeClientProxiesTable < ActiveRecord::Migration[7.1]
  def change
    create_table :ce_client_proxies do |t|
      t.references :client, null: false, polymorphic: true
      t.timestamps
    end

    safety_assured do
      # Data deletion is safe here because
      # - we can regenerate candidates by re-running the match job
      # - CE is not yet used in production envs
      # This simplification allows us to add the ce_client_proxy reference and remove the client reference in the same migration.
      Hmis::Ce::Match::Candidate.delete_all
      add_reference :ce_match_candidates, :client_proxy, null: false, foreign_key: { to_table: :ce_client_proxies }, index: true
      add_index :ce_match_candidates, [:candidate_pool_id, :client_proxy_id], unique: true, name: 'index_ce_match_candidates_proxy_uniq'
      remove_reference :ce_match_candidates, :client
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20250625170425
# rails db:migrate:down:warehouse VERSION=20250625170425
