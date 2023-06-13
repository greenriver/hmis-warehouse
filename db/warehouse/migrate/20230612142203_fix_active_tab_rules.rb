class FixActiveTabRules < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::Cohort.find_each do |cohort|
      GrdaWarehouse::CohortTab.default_rules.each.with_index do |rule|
        next unless rule[:name] == 'Active Clients'

        cohort.cohort_tabs.where(name: 'Active Clients').update(**rule)
      end
    end
  end
end
