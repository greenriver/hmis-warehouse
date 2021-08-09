class CreateCeAprCeEvents < ActiveRecord::Migration[5.2]
  def change
    change_table :hud_report_apr_clients do |t|
      t.date :ce_assessment_date
      t.integer :ce_assessment_type
      t.integer :ce_assessment_prioritization_status
      t.date :ce_event_date
      t.integer :ce_event_event
      t.integer :ce_event_problem_sol_div_rr_result
      t.integer :ce_event_referral_case_manage_after
      t.integer :ce_event_referral_result
    end

    create_table :hud_report_apr_ce_assessments do |t|
      t.references :hud_report_apr_client
      t.references :project
      t.date :assessment_date
      t.integer :assessment_level
    end

    create_table :hud_report_apr_ce_events do |t|
      t.references :hud_report_apr_client
      t.references :project
      t.date :event_date
      t.integer :event
      t.integer :problem_sol_div_rr_result
      t.integer :referral_case_manage_after
      t.integer :referral_result
    end
  end
end
