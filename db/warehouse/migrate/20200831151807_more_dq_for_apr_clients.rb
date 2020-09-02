class MoreDqForAprClients < ActiveRecord::Migration[5.2]
  def change
    change_table :hud_report_apr_clients do |t|
      t.integer :destination
      t.date :income_date_at_start
      t.integer :income_from_any_source_at_start
      t.jsonb :income_sources_at_start
      t.boolean :annual_assessment_expected
      t.date :income_date_at_annual_assessment
      t.integer :income_from_any_source_at_annual_assessment
      t.jsonb :income_sources_at_annual_assessment
      t.date :income_date_at_exit
      t.integer :income_from_any_source_at_exit
      t.jsonb :income_sources_at_exit
      t.integer :project_type
      t.integer :prior_living_situation
      t.integer :prior_length_of_stay
      t.date :date_homeless
      t.integer :times_homeless
      t.integer :months_homeless
      t.integer :came_from_street_last_night
    end
  end
end
