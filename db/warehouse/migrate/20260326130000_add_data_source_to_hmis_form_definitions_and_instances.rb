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
  def change
    reversible do |dir|
      dir.up { validate_hmis_exists_if_needed }
      dir.down {}
    end

    safety_assured do
      add_data_source_refs
      populate_data_source_refs
      make_data_source_refs_non_nullable
      drop_old_indices
      add_new_indices
    end
  end

  protected

  def validate_hmis_exists_if_needed
    oldest_id = GrdaWarehouse::DataSource.hmis.order(:created_at).limit(1).pick(:id)
    return if oldest_id

    def_count = connection.select_value('SELECT COUNT(*) FROM hmis_form_definitions').to_i
    inst_count = connection.select_value('SELECT COUNT(*) FROM hmis_form_instances').to_i
    return unless def_count.positive? || inst_count.positive?

    raise ActiveRecord::MigrationError, 'Unexpected state: Environment has HMIS forms but no HMIS data source. Delete forms or configure HMIS data source before this migration can run'
  end

  def add_data_source_refs
    reversible do |dir|
      dir.up do
        add_reference :hmis_form_definitions, :data_source, null: true
        add_reference :hmis_form_instances, :data_source, null: true
      end
      dir.down do
        remove_reference :hmis_form_instances, :data_source
        remove_reference :hmis_form_definitions, :data_source
      end
    end
  end

  def populate_data_source_refs
    reversible do |dir|
      dir.up do
        oldest_id = GrdaWarehouse::DataSource.hmis.order(:created_at).limit(1).pick(:id)
        next unless oldest_id

        quoted_id = connection.quote(oldest_id)
        execute "UPDATE hmis_form_definitions SET data_source_id = #{quoted_id} WHERE data_source_id IS NULL"
        execute "UPDATE hmis_form_instances SET data_source_id = #{quoted_id} WHERE data_source_id IS NULL"
      end
      dir.down do
        # Column is dropped in add_data_source_refs; no backfill needed on rollback.
      end
    end
  end

  def make_data_source_refs_non_nullable
    reversible do |dir|
      dir.up do
        change_column_null :hmis_form_definitions, :data_source_id, false
        change_column_null :hmis_form_instances, :data_source_id, false
      end
      dir.down do
        # no need to remove NOT NULL since the columns are dropped
      end
    end
  end

  def drop_old_indices
    reversible do |dir|
      dir.up do # Drop old indices that need to be updated to include data_source_id
        remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_identifier', if_exists: true
        remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_draft_per_identifier', if_exists: true
        remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_published_per_identifier', if_exists: true
      end
      dir.down do
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
      end
    end
  end

  def add_new_indices
    reversible do |dir|
      dir.up do # Replace old uniqueness indices with new ones that include data_source_id
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
      dir.down do
        remove_index :hmis_form_instances, name: 'index_hmis_form_instances_on_ds_and_identifier', if_exists: true

        remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_published_per_identifier', if_exists: true
        remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_one_draft_per_identifier', if_exists: true
        remove_index :hmis_form_definitions, name: 'uidx_hmis_form_definitions_ds_identifier_version', if_exists: true
      end
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260326130000
# rails db:migrate:down:warehouse VERSION=20260326130000
