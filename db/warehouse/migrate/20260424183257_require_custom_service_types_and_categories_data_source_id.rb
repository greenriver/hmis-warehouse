###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RequireCustomServiceTypesAndCategoriesDataSourceId < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      backfill_null_data_source_ids
      change_column_null 'CustomServiceCategories', :data_source_id, false
      change_column_null 'CustomServiceTypes', :data_source_id, false
    end
  end

  def down
    change_column_null 'CustomServiceTypes', :data_source_id, true
    change_column_null 'CustomServiceCategories', :data_source_id, true
  end

  private

  def backfill_null_data_source_ids
    cat_null = connection.select_value('SELECT COUNT(*) FROM "CustomServiceCategories" WHERE data_source_id IS NULL').to_i
    type_null = connection.select_value('SELECT COUNT(*) FROM "CustomServiceTypes" WHERE data_source_id IS NULL').to_i
    return if cat_null.zero? && type_null.zero?

    oldest_id = GrdaWarehouse::DataSource.hmis.order(:created_at).limit(1).pick(:id)
    raise ActiveRecord::MigrationError, 'CustomServiceCategories/CustomServiceTypes rows have NULL data_source_id but no HMIS data source exists' unless oldest_id

    quoted = connection.quote(oldest_id)
    execute <<~SQL.squish
      UPDATE "CustomServiceCategories" SET data_source_id = #{quoted} WHERE data_source_id IS NULL
    SQL
    execute <<~SQL.squish
      UPDATE "CustomServiceTypes" SET data_source_id = #{quoted} WHERE data_source_id IS NULL
    SQL
  end
end

# rails db:migrate:up:warehouse VERSION=20260424183257
# rails db:migrate:down:warehouse VERSION=20260424183257
