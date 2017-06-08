class CreateHealthGoals < ActiveRecord::Migration
  def change

    create_table :careplans do |t|
      t.references :patient, index: true
      t.references :user, index: true
      t.date :sdh_enroll_date
      t.date :first_meeting_with_case_manager_date
      t.date :self_sufficiency_baseline_due_date
      t.date :self_sufficiency_final_due_date
      t.date :self_sufficiency_baseline_completed_date
      t.date :self_sufficiency_final_completed_date


      t.datetime :deleted_at
      t.timestamps
    end

    create_table :health_goals do |t|
      t.references :careplan, index: true
      t.references :user, index: true
      t.string :type
      t.integer :number
      t.string :name
      t.string :associated_dx
      t.string :barriers
      t.string :provider_plan
      t.string :case_manager_plan
      t.string :rn_plan
      t.string :bh_plan
      t.string :other_plan
      t.integer :confidence
      t.string :az_housing
      t.string :az_income
      t.string :az_non_cash_benefits
      t.string :az_disabilities
      t.string :az_food
      t.string :az_employment
      t.string :az_training
      t.string :az_transportation
      t.string :az_life_skills
      t.string :az_health_care_coverage
      t.string :az_physical_health
      t.string :az_mental_health
      t.string :az_substance_use
      t.string :az_criminal_justice
      t.string :az_legal
      t.string :az_safety
      t.string :az_risk
      t.string :az_family
      t.string :az_community
      t.string :az_time_management


      t.datetime :deleted_at
      t.timestamps
    end
  end
end
