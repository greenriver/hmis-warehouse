# frozen_string_literal: true

class CreateHudReportCheckpoints < ActiveRecord::Migration[7.2]
  def change
    create_table :hud_report_checkpoints do |t|
      t.references :hud_report_instance, null: false
      t.string :name, null: false
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
    end
  end
end
