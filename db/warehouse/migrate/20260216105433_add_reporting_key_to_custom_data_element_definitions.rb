# frozen_string_literal: true

class AddReportingKeyToCustomDataElementDefinitions < ActiveRecord::Migration[7.2]
  def change
    # Add nullable reporting_key column, max 63 characters
    add_column :CustomDataElementDefinitions, :reporting_key, :string, limit: 63

    # When reporting_key is present, it should be unique for its owner type on non-deleted records
    safety_assured do
      add_index :CustomDataElementDefinitions,
                [:owner_type, :reporting_key],
                unique: true,
                where: '"reporting_key" IS NOT NULL AND "DateDeleted" IS NULL',
                name: 'index_cded_on_owner_type_and_reporting_key'
    end

    add_check_constraint :CustomDataElementDefinitions,
                         "reporting_key IS NULL OR reporting_key ~ '^[a-z][a-z0-9_]{0,62}$'",
                         name: 'chk_cded_reporting_key_format',
                         validate: false # StrongMigrations suggestion: there are no existing rows, so no need to validate

    update_view 'analytics.custom_data_element_definitions', version: 2, revert_to_version: 1
  end
end

# rails db:migrate:up:warehouse VERSION=20260216105433
# rails db:migrate:down:warehouse VERSION=20260216105433
