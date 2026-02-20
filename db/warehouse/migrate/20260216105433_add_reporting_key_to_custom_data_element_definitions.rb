# frozen_string_literal: true

class AddReportingKeyToCustomDataElementDefinitions < ActiveRecord::Migration[7.2]
  def change
    # Add nullable reporting_key column
    add_column :CustomDataElementDefinitions, :reporting_key, :string

    # When reporting_key is present, it should be unique for its owner type
    safety_assured do
      add_index :CustomDataElementDefinitions,
                [:owner_type, :reporting_key],
                unique: true,
                where: '"reporting_key" IS NOT NULL',
                name: 'index_cded_on_owner_type_and_reporting_key'
    end

    update_view 'analytics.custom_data_element_definitions', version: 2, revert_to_version: 1
  end
end

# rails db:migrate:up:warehouse VERSION=20260216105433
# rails db:migrate:down:warehouse VERSION=20260216105433
