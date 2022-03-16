class AddPitEnrollmentsToAprClient < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :pit_enrollments, :jsonb, default: []
  end
end
