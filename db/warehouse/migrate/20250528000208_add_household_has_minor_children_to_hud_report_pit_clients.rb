# frozen_string_literal: true

class AddHouseholdHasMinorChildrenToHudReportPitClients < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_pit_clients, :household_has_minor_children, :boolean
  end
end
