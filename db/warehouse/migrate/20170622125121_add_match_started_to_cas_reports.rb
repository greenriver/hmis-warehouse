class AddMatchStartedToCasReports < ActiveRecord::Migration
  def change
    add_column :cas_reports, :match_started_at, :datetime
  end
end
