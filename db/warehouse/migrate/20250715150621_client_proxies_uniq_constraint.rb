# frozen_string_literal: true

class ClientProxiesUniqConstraint < ActiveRecord::Migration[7.1]
  OLD_INDEX_NAME = 'index_ce_client_proxies_on_client'
  NEW_INDEX_NAME = 'index_ce_client_proxies_on_client_unique'

  def up
    safety_assured do
      # to add a uniq index, we just delete the records for now as CE is not in prod at this point.
      # The matches and proxies will regenerate (run HmisUtil::CeBuilder.build_candidate_pools)
      execute('DELETE FROM ce_match_candidates')
      execute('DELETE FROM ce_client_proxies')

      # or we could deduplicate if needed but then we need to also handle references. Would be something like:
      # execute(<<-SQL.squish)
      #   DELETE FROM ce_client_proxies
      #   WHERE id IN (
      #     SELECT id FROM (
      #       SELECT id, row_number() OVER (PARTITION BY client_id, client_type ORDER BY id) as row_num
      #       FROM ce_client_proxies
      #     ) AS duplicates
      #     WHERE duplicates.row_num > 1
      #   )
      # SQL

      remove_index :ce_client_proxies, name: OLD_INDEX_NAME
      add_index :ce_client_proxies, [:client_type, :client_id], unique: true, name: NEW_INDEX_NAME
    end
  end

  def down
    safety_assured do
      remove_index :ce_client_proxies, name: NEW_INDEX_NAME
      add_index :ce_client_proxies, [:client_type, :client_id], name: OLD_INDEX_NAME
    end
  end
end
