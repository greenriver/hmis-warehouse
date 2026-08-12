# frozen_string_literal: true

class RemoveEnabledFromHmisProjectConfigs < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      remove_column :hmis_project_configs, :enabled, :boolean, default: true, null: false
    end
  end

  def down
    add_column :hmis_project_configs, :enabled, :boolean, default: true, null: false

    safety_assured do
      execute(<<~SQL)
        UPDATE hmis_project_configs
        SET enabled = FALSE
        WHERE deleted_at IS NOT NULL
      SQL
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260812172057
# rails db:migrate:down:warehouse VERSION=20260812172057
