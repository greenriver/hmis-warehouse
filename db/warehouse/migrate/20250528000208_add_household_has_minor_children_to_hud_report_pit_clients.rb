# frozen_string_literal: true

class AddHouseholdHasMinorChildrenToHudReportPitClients < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_pit_clients, :household_has_minor_children, :boolean, comment: 'only counts minor children (rel 2, age < 18)'
    add_column :hud_report_pit_clients, :household_max_age_of_parents, :integer, comment: 'max age of hoh or spouse (rel 1, 3)'
  end
end
