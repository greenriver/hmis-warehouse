###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddEntityTypeToContacts < ActiveRecord::Migration[7.1]
  def up
    add_column :contacts, :entity_type, :string

    safety_assured do
      # Backfill entity_type based on existing type (STI) column
      execute <<-SQL.squish
        UPDATE contacts
        SET entity_type = CASE
          WHEN type = 'GrdaWarehouse::Contact::Organization' THEN 'GrdaWarehouse::Hud::Organization'
          WHEN type = 'GrdaWarehouse::Contact::Project' THEN 'GrdaWarehouse::Hud::Project'
          WHEN type = 'GrdaWarehouse::Contact::User' THEN 'User'
          ELSE NULL
        END
      SQL

      add_index :contacts, [:entity_type, :entity_id]
    end
  end

  def down
    remove_index :contacts, [:entity_type, :entity_id]
    remove_column :contacts, :entity_type
  end
end
