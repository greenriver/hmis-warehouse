# frozen_string_literal: true

class AddDeletedAtToHmisProjectConfigs < ActiveRecord::Migration[8.1]
  def up
    add_column :hmis_project_configs, :deleted_at, :datetime

    safety_assured do
      add_index :hmis_project_configs, :deleted_at

      # Preserve disabled configs as soft-deleted. Raw SQL avoids coupling the migration to the model
      execute(<<~SQL)
        UPDATE hmis_project_configs
        SET deleted_at = NOW()
        WHERE enabled = FALSE AND deleted_at IS NULL
      SQL
    end
  end

  def down
    safety_assured do
      execute(<<~SQL)
        UPDATE hmis_project_configs
        SET enabled = FALSE
        WHERE deleted_at IS NOT NULL
      SQL
    end

    remove_index :hmis_project_configs, :deleted_at
    remove_column :hmis_project_configs, :deleted_at
  end
end

# rails db:migrate:up:warehouse VERSION=20260812160243
# rails db:migrate:down:warehouse VERSION=20260812160243
