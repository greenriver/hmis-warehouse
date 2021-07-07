class CreateHousingResolutionPlan < ActiveRecord::Migration[5.2]
  def change
    create_table :housing_resolution_plans do |t|
      t.references :client
      t.references :user

      t.string :pronouns
      t.date :planned_on
      t.string :staff_name
      t.string :location
      t.string :chosen_resolution
      t.string :temporary_resolution
      t.string :plan_description
      t.string :action_steps
      t.string :backup_plan
      t.date :next_checkin
      t.string :how_to_contact
      t.string :psc_attempted
      t.string :psc_why_not
      t.string :resolution_achieved
      t.string :resolution_why_not
      t.string :problem_solving_point
      t.jsonb :housing_crisis_causes
      t.string :housing_crisis_cause_other
      t.string :factor_employment_income
      t.string :factor_family_supports
      t.string :factor_social_supports
      t.string :factor_life_skills

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
