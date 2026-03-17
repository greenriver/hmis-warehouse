# frozen_string_literal: true

class RemoveUnusedColumnsFromHouseholdContexts < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      # remove extra fields that are either redundant or not needed for current reports
      change_table :hud_report_household_contexts do |t|
        t.remove :pit_chronic_status
        t.remove :inherited_pit_chronic_status
        t.remove :inherited_pit_chronic_detail
        t.remove :raw_pit_chronic_status
        t.remove :raw_pit_chronic_detail
        t.remove :hh_any_veteran_chronic
        t.remove :hh_any_veteran_non_chronic
        t.remove :hh_all_adult_non_veteran
        t.remove :hh_any_adult_refused_veteran
        t.remove :hh_any_adult_missing_veteran
        t.remove :hh_has_minor_children
        t.remove :hh_max_age_of_parents
        t.remove :member_count
      end
    end
  end
end
