# frozen_string_literal: true

class AddDataSourceIdToHmisProjectConfigs < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      add_reference :hmis_project_configs, :data_source, null: true, foreign_key: true

      # This does nothing if there are no project configs or HMIS data sources.
      execute <<-SQL.squish
        UPDATE hmis_project_configs
        SET data_source_id = (
          SELECT id FROM data_sources WHERE hmis IS NOT NULL ORDER BY id ASC LIMIT 1
        )
      SQL

      # If there are project configs but no HMIS data source (which would be unexpected), this raises ActiveRecord::NotNullViolation
      change_column_null :hmis_project_configs, :data_source_id, false
    end
  end

  def down
    safety_assured do
      remove_reference :hmis_project_configs, :data_source
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260413070708
# rails db:migrate:down:warehouse VERSION=20260413070708
