# frozen_string_literal: true

class AddCheckpointsToHudReportInstances < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_instances, :checkpoints, :jsonb, default: [], null: false
  end
end
