# frozen_string_literal: true

class AddRawChronicAndExitDateToHouseholdContexts < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_table :hud_report_household_contexts do |t|
        t.boolean :raw_chronic_status
        t.string :raw_chronic_detail
        t.boolean :raw_pit_chronic_status
        t.string :raw_pit_chronic_detail
        t.date :member_exit_date
      end
    end
  end
end
