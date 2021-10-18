class CreatePerformanceMeasurementSubTables < ActiveRecord::Migration[5.2]
  def change
    create_table :pm_clients do |t|
      t.references :report
      t.references :client
      t.date :dob
      t.boolean :veteran, default: false, null: false
      [
        :reporting,
        :comparison,
      ].each do |period|
        t.integer "#{period}_age"
        t.boolean "#{period}_hoh", default: false, null: false
        t.boolean "#{period}_stayer", default: false, null: false
        t.boolean "#{period}_leaver", default: false, null: false
        t.boolean "#{period}_first_time", default: false, null: false
        t.integer "#{period}_days_homeless_es_sh_th"
        t.integer "#{period}_days_homeless_before_move_in"
        t.integer "#{period}_destination"
        t.integer "#{period}_days_to_return"
        t.boolean "#{period}_increased_income", default: false, null: false
        t.integer "#{period}_pit_project_id"
        t.integer "#{period}_pit_project_type"
        t.boolean "#{period}_served_on_pit_date", default: false, null: false
        t.boolean "#{period}_served_in_so", default: false, null: false
        t.integer "#{period}_current_project_types", array: true
        t.integer "#{period}_prior_project_types", array: true
        t.integer "#{period}_so_destination"
        t.integer "#{period}_es_sh_th_rrh_destination"
        t.integer "#{period}_moved_in_destination"
        t.integer "#{period}_moved_in_stayer"
        t.boolean "#{period}_so_es_sh_th_2_yr_permanent_dest", default: false, null: false
        t.boolean "#{period}_so_es_sh_th_return_6_mo", default: false, null: false
        t.boolean "#{period}_so_es_sh_th_return_2_yr", default: false, null: false
        t.integer "#{period}_prior_living_situation"
        t.integer "#{period}_prevention_tool_score"
        t.boolean "#{period}_ce_enrollment", default: false, null: false
        t.boolean "#{period}_ce_diversion", default: false, null: false
        t.integer "#{period}_days_in_ce"
        t.integer "#{period}_days_since_assessment"
        t.integer "#{period}_days_ce_to_assessment"
        t.integer "#{period}_days_ce_to_referral"
        t.integer "#{period}_days_referral_to_ph_entry"
        t.integer "#{period}_ce_assessment_score"
      end

      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
    add_index :pm_clients, [:client_id, :report_id]

    create_table :pm_client_projects do |t|
      t.references :client
      t.references :project
      t.boolean :reporting_period, default: false, null: false
      t.boolean :comparison_period, default: false, null: false
      t.datetime :deleted_at, index: true
    end
    add_index :pm_client_projects, [:client_id, :project_id, :comparison_period], name: :pm_pc_comparison_index
    add_index :pm_client_projects, [:client_id, :project_id, :reporting_period], name: :pm_pc_reporting_index

    create_table :pm_projects do |t|
      t.references :report
      t.boolean :reporting_period, default: false, null: false
      t.boolean :comparison_period, default: false, null: false
      [
        :reporting,
        :comparison,
      ].each do |period|
        t.float "#{period}_ave_bed_capacity_per_night"
        t.float "#{period}_ave_clients_per_night"
      end
      t.datetime :deleted_at, index: true
    end
    add_index :pm_client_projects, [:project_id, :comparison_period]
    add_index :pm_client_projects, [:project_id, :reporting_period]
  end
end
