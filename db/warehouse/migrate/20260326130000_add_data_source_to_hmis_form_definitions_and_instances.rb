# frozen_string_literal: true

##
# This migration adds a data_source_id column to the hmis_form_definitions and hmis_form_instances tables.
# It migrates existing rows to point to the oldest HMIS data source,
# and updates appropriate indexes to use the data_source_id.
#
# Note about the use of safety_assured in this migration:
# StrongMigrations had a lot of suggestions about avoiding locking the whole table while building indexes or changing column nullability.
# But these tables are expected to be tiny (dozens to a couple hundred rows in prod), so the operations will be fast, and a short lock is acceptable.
#
class AddDataSourceToHmisFormDefinitionsAndInstances < ActiveRecord::Migration[7.2]
  def up
    oldest_id = GrdaWarehouse::DataSource.hmis.order(:created_at).limit(1).pick(:id)
    unless oldest_id
      # handle non-HMIS installations where no data source exists:
      # Raise only if there exist rows in the relevant tables.
      def_count = connection.select_value('SELECT COUNT(*) FROM hmis_form_definitions').to_i
      inst_count = connection.select_value('SELECT COUNT(*) FROM hmis_form_instances').to_i
      raise ActiveRecord::MigrationError, 'Unexpected state: Environment has HMIS forms but no HMIS data source. Delete forms or configure HMIS data source before this migration can run' if def_count.positive? || inst_count.positive?
    end

    safety_assured do
      # Add references to data source. Nullable at first since we need to back-populate existing rows.
      add_reference :hmis_form_definitions, :data_source, null: true
      add_reference :hmis_form_instances, :data_source, null: true
    end

    if oldest_id
      safety_assured do
        # Update the new DS column to point to the oldest existing HMIS data source
        quoted_id = connection.quote(oldest_id)
        execute "UPDATE hmis_form_definitions SET data_source_id = #{quoted_id} WHERE data_source_id IS NULL"
        execute "UPDATE hmis_form_instances SET data_source_id = #{quoted_id} WHERE data_source_id IS NULL"
      end
    end

    safety_assured do
      # Require the data_source_id column
      change_column_null :hmis_form_definitions, :data_source_id, false
      change_column_null :hmis_form_instances, :data_source_id, false
    end

    # Remove existing uniqueness indexes
    remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_identifier', if_exists: true
    remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_draft_per_identifier', if_exists: true
    remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_published_per_identifier', if_exists: true

    safety_assured do
      # Re-add uniqueness indexes with data_source_id.
      add_index :hmis_form_definitions,
                [:data_source_id, :identifier, :version],
                unique: true,
                where: 'deleted_at IS NULL',
                name: 'uidx_hmis_form_definitions_ds_identifier_version'

      add_index :hmis_form_definitions,
                [:data_source_id, :identifier],
                unique: true,
                where: "status = 'draft' AND deleted_at IS NULL",
                name: 'uidx_hmis_form_definitions_one_draft_per_identifier'

      add_index :hmis_form_definitions,
                [:data_source_id, :identifier],
                unique: true,
                where: "status = 'published' AND deleted_at IS NULL",
                name: 'uidx_hmis_form_definitions_one_published_per_identifier'

      add_index :hmis_form_instances, [:data_source_id, :definition_identifier], name: 'index_hmis_form_instances_on_ds_and_identifier'
    end
  end

  def down
    remove_index :hmis_form_instances, name: 'index_hmis_form_instances_on_ds_and_identifier', if_exists: true

    remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_published_per_identifier', if_exists: true
    remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_draft_per_identifier', if_exists: true
    remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_ds_identifier_version', if_exists: true

    change_column_null :hmis_form_instances, :data_source_id, true
    change_column_null :hmis_form_definitions, :data_source_id, true

    add_index :hmis_form_definitions,
              [:identifier, :version],
              unique: true,
              where: '(deleted_at IS NULL)',
              name: 'uidx_hmis_form_definitions_identifier'

    add_index :hmis_form_definitions,
              [:identifier],
              unique: true,
              where: "((status)::text = 'draft'::text) AND (deleted_at IS NULL)",
              name: 'uidx_hmis_form_definitions_one_draft_per_identifier'

    add_index :hmis_form_definitions,
              [:identifier],
              unique: true,
              where: "((status)::text = 'published'::text) AND (deleted_at IS NULL)",
              name: 'uidx_hmis_form_definitions_one_published_per_identifier'

    remove_reference :hmis_form_instances, :data_source
    remove_reference :hmis_form_definitions, :data_source
  end
end

# rails db:migrate:up:warehouse VERSION=20260326130000
# rails db:migrate:down:warehouse VERSION=20260326130000
