class SetDefaultTabs < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::Cohort.find_each do |cohort|
      GrdaWarehouse::CohortTab.default_rules.each do |name, rules|
        cohort.cohort_tabs.create(name: name, rules: rules)
      end
    end
  end
end
