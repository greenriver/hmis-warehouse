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
      t.date :exit_created
      t.integer :project_tracking_method
      t.date :date_of_last_bed_night
      t.boolean :other_clients_over_25
    end

    create_table :hud_report_apr_living_situations do |t|
      t.references :hud_report_apr_client, index: {unique: true, name: 'index_hud_apr_client_liv_sit'}
      t.date :information_date

      t.timestamps
    end
  end
end
