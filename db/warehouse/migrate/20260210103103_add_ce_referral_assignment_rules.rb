# frozen_string_literal: true

class AddCeReferralAssignmentRules < ActiveRecord::Migration[7.2]
  def change
    add_column :ce_referrals, :assignment_rules, :jsonb, null: false, default: []

    # Backfill assignment rules on existing referrals from their corresponding opportunities.
    # We could achieve this without raw SQL, but it's bad practice to use rails models in a migration.
    # Hmis::Ce::Referral.joins(:opportunity).includes(:opportunity).find_each do |referral|
    #   referral.update_column(:assignment_rules, referral.opportunity.assignment_rules)
    # end
    reversible do |dir|
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
