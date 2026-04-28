# frozen_string_literal: true

class AddUniqueIndexToDataSourcesOnHmisDomain < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :data_sources, :hmis,
              unique: true,
              where: 'deleted_at IS NULL AND hmis IS NOT NULL',
              name: :uidx_data_sources_on_hmis_where_active,
              algorithm: :concurrently
  end
end

# rails db:migrate:up:warehouse VERSION=20260428124420
# rails db:migrate:down:warehouse VERSION=20260428124420
