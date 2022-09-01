class AddEnrollmentInfoToAprClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :source_enrollment_id, :integer
    add_column :hud_report_apr_clients, :los_under_threshold, :integer
  end
end
