class AddArchiveToProjectScorecards < ActiveRecord::Migration[5.2]
  def change
    add_column :project_scorecard_reports, :archive, :string
  end
end
