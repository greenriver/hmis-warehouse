class ProjectScoreCardAdditionalFields < ActiveRecord::Migration[5.2]
  def change
    add_column :project_scorecard_reports, :expansion_year, :boolean
    add_column :project_scorecard_reports, :special_population_only, :string
    add_column :project_scorecard_reports, :project_less_than_two, :boolean
    add_column :project_scorecard_reports, :geographic_location, :string
  end
end
