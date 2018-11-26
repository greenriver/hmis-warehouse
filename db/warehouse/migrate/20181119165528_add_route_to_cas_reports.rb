class AddRouteToCasReports < ActiveRecord::Migration
  def change
    add_column :cas_reports, :match_route, :string
  end
end
