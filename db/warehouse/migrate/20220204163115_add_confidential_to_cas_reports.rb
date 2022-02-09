class AddConfidentialToCasReports < ActiveRecord::Migration[6.1]
  def change
    add_column :cas_reports, :confidential, :boolean, default: false
  end
end
