class AddFailedAtToHudReports < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_instances, :failed_at, :datetime
  end
end
