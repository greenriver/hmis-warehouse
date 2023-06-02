class SetDefaultTabs < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::Cohort.find_each do |cohort|
      GrdaWarehouse::CohortTab.default_rules.each.with_index do |rule|
        cohort.cohort_tabs.create(**rule)
      end
    end
  end

  def down
     GrdaWarehouse::CohortTab.delete_all
  end
end
