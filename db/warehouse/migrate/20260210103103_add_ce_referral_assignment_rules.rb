# frozen_string_literal: true

class AddCeReferralAssignmentRules < ActiveRecord::Migration[7.2]
  def change
    add_column :ce_referrals, :assignment_rules, :jsonb, null: false, default: []

    # Backfill assignment rules on existing referrals from their corresponding opportunities.
    reversible do |dir| # reversible with only `up` block tells ActiveRecord that nothing needs to be done on `down`
      dir.up do
        safety_assured do
          execute <<-SQL.squish
            UPDATE ce_referrals
            SET assignment_rules = ce_opportunities.assignment_rules
            FROM ce_opportunities
            WHERE ce_referrals.opportunity_id = ce_opportunities.id
          SQL
        end
      end
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260210103103
# rails db:migrate:down:warehouse VERSION=20260210103103
