# frozen_string_literal: true

class ChangeOpportunityOwnerToUnit < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      add_reference :ce_opportunities, :unit, foreign_key: { to_table: :hmis_units }

      # Populate unit_id with owner_id where owner_type is 'Hmis::Unit'
      reversible do |dir|
        dir.up do
          execute <<-SQL.squish
            UPDATE ce_opportunities
            SET unit_id = owner_id
            WHERE owner_type = 'Hmis::Unit'
          SQL
        end
      end

      # Make unit_id non-nullable
      change_column_null :ce_opportunities, :unit_id, false

      # Remove owner_type and owner_id columns
      remove_column :ce_opportunities, :owner_type, :string
      remove_column :ce_opportunities, :owner_id, :integer
    end
  end
end
