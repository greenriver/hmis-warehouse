class AddProcessingToEdIpFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :ed_ip_visit_files, :started_at, :datetime
    add_column :ed_ip_visit_files, :completed_at, :datetime
    add_column :ed_ip_visit_files, :failed_at, :datetime
  end
end
