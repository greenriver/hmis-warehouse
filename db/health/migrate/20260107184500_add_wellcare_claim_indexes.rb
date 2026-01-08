# frozen_string_literal: true

class AddWellcareClaimIndexes < ActiveRecord::Migration[7.1]
  def change
    # NO-OP, manually added, may need additional permissions to run in the migration context
  end
  # disable_ddl_transaction!

  # def up
  #   return unless extensions_enabled?

  #   safety_assured do
  #     execute <<~SQL
  #       CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_crmc_dx1_trgm_v10
  #       ON claims_reporting_medical_claims
  #       USING gin (dx_1 gin_trgm_ops)
  #       WHERE icd_version = '10' AND dx_1 IS NOT NULL;
  #     SQL

  #     execute <<~SQL
  #       CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_crmc_dx2_trgm_v10
  #       ON claims_reporting_medical_claims
  #       USING gin (dx_2 gin_trgm_ops)
  #       WHERE icd_version = '10' AND dx_2 IS NOT NULL;
  #     SQL

  #     execute <<~SQL
  #       CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_crmc_member_proc_start_v10
  #       ON claims_reporting_medical_claims (member_id, procedure_code, service_start_date)
  #       WHERE icd_version = '10';
  #     SQL

  #     # NOTE: this may take a long time to build
  #     execute <<~SQL
  #       CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_crmc_member_service_daterange_v10
  #       ON claims_reporting_medical_claims
  #       USING gist (member_id, daterange(service_start_date, service_end_date, '[]'))
  #       WHERE icd_version = '10';
  #     SQL
  #   end
  # end

  # def down
  #   execute 'DROP INDEX CONCURRENTLY IF EXISTS idx_crmc_dx1_trgm_v10'
  #   execute 'DROP INDEX CONCURRENTLY IF EXISTS idx_crmc_dx2_trgm_v10'
  #   execute 'DROP INDEX CONCURRENTLY IF EXISTS idx_crmc_member_proc_start_v10'
  #   execute 'DROP INDEX CONCURRENTLY IF EXISTS idx_crmc_member_service_daterange_v10'
  # end

  # def extensions_enabled?
  #   extensions = connection.execute("SELECT extname FROM pg_extension WHERE extname IN ('pg_trgm', 'btree_gist')").map { |row| row['extname'] }
  #   extensions.include?('pg_trgm') && extensions.include?('btree_gist')
  # end
end
