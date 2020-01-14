class AddRouteToCasReports < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :match_route, :string
  end
end
