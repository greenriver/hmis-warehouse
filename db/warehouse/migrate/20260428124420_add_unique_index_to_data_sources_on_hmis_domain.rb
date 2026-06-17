###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddUniqueIndexToDataSourcesOnHmisDomain < ActiveRecord::Migration[7.2]
  def change
    # Omit `algorithm: :concurrently`, so the migration runs in one transaction.
    # This avoids needing disable_ddl_transaction! which we've had issues with in the past.
    # The `data_sources` table is small and not written to frequently, so a brief build lock is acceptable.
    safety_assured do
      add_index :data_sources, :hmis,
                unique: true,
                where: 'deleted_at IS NULL AND hmis IS NOT NULL',
                name: :uidx_data_sources_on_hmis_where_active
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260428124420
# rails db:migrate:down:warehouse VERSION=20260428124420
