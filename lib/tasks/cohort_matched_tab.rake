# frozen_string_literal: true

# One-time task to add a "Matched" tab to a specific cohort and update the
# "Active Clients" tab to exclude fully-matched clients (user_boolean_1 = true
# AND user_string_1 is present).
#
# Usage:
#   rails cohort:add_matched_tab[<cohort_id>]
#
# The task is idempotent — it aborts cleanly if the "Matched" tab already exists.
namespace :cohort do
  desc 'Add a Matched tab to a cohort and update Active Clients to exclude matched clients'
  task :add_matched_tab, [:cohort_id] => [:environment] do |_t, args|
    cohort_id = args[:cohort_id].presence&.to_i
    abort 'Usage: rails "cohort:add_matched_tab[<cohort_id>]"' unless cohort_id

    cohort = GrdaWarehouse::Cohort.find_by(id: cohort_id)
    abort "Cohort #{cohort_id} not found." unless cohort

    existing_matched = cohort.cohort_tabs.find_by(name: 'Matched')
    abort "Cohort #{cohort_id} already has a 'Matched' tab (id=#{existing_matched.id}). Aborting." if existing_matched

    active_tab = cohort.cohort_tabs.find_by(name: 'Active Clients')
    abort "Cohort #{cohort_id} has no 'Active Clients' tab. Aborting." unless active_tab

    # The "matched" condition: user_boolean_1 = TRUE AND user_string_1 is present.
    matched_condition = {
      'operator' => 'and',
      'left' => { 'column' => 'user_boolean_1', 'operator' => '==', 'value' => true },
      'right' => { 'column' => 'user_string_1', 'operator' => '<>', 'value' => nil },
    }

    # Wrap the existing Active Clients rules (preserving any prior customizations)
    # with a NOT-matched exclusion.
    updated_active_rules = {
      'operator' => 'and',
      'left' => active_tab.rules,
      'right' => { 'operator' => 'not', 'operand' => matched_condition },
    }

    # Matched tab: existing Active Clients criteria plus the matched condition.
    matched_rules = {
      'operator' => 'and',
      'left' => active_tab.rules,
      'right' => matched_condition,
    }

    matched_order = active_tab.order + 1

    GrdaWarehouse::Cohort.transaction do
      active_tab.update!(rules: updated_active_rules)

      # Bump tabs currently at or beyond the insertion point to make room.
      cohort.cohort_tabs.where('"order" >= ?', matched_order).find_each do |t|
        t.update!(order: t.order + 1)
      end

      matched_tab = cohort.cohort_tabs.create!(
        name: 'Matched',
        order: matched_order,
        permissions: [],
        base_scope: 'current_scope',
        rules: matched_rules,
      )

      puts "Cohort #{cohort_id} updated successfully.\n\n"

      tab_instance = GrdaWarehouse::CohortTab.new

      puts "Active Clients SQL:\n  #{tab_instance.rule_query(nil, active_tab.reload.rules).to_sql}\n\n"
      puts "Matched SQL:\n  #{tab_instance.rule_query(nil, matched_tab.rules).to_sql}\n\n"

      puts 'Verify the SQL above looks correct.'
    end
  end
end
