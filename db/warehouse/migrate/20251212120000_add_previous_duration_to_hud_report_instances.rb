# frozen_string_literal: true

class AddPreviousDurationToHudReportInstances < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_instances, :previous_duration, :integer, default: 0, null: false
  end
end
