class AddMatchStartedToCasReports < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :match_started_at, :datetime
  end
end
