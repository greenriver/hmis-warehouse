class CreateVprs < ActiveRecord::Migration[5.2]
  def change
    create_table :health_flexible_service_vprs do |t|
      t.references :patient, index: true, null: false
      t.references :user, index: true, null: false
      t.date :planned_on
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.date :dob
      t.string :accommodations_needed
      t.string :contact_type
      t.string :phone
      t.string :email
      t.text :additional_contact_details
      t.string :main_contact_first_name
      t.string :main_contact_last_name
      t.string :main_contact_organization
      t.string :main_contact_phone
      t.string :main_contact_email
      t.string :reviewer_first_name
      t.string :reviewer_last_name
      t.string :reviewer_organization
      t.string :reviewer_phone
      t.string :reviewer_email
      t.string :representative_first_name
      t.string :representative_last_name
      t.string :representative_organization
      t.string :representative_phone
      t.string :representative_email
      t.boolean :member_agrees_to_plan
      t.text :member_agreement_notes
      t.boolean :aco_approved
      t.date :aco_approved_on
      t.text :aco_rejection_notes

      t.date :health_needs_screened_on
      t.boolean :complex_physical_health_need
      t.string :complex_physical_health_need_detail
      t.boolean :behavioral_health_need
      t.string :behavioral_health_need_detail
      t.boolean :activities_of_daily_living
      t.string :activities_of_daily_living_detail
      t.boolean :ed_utilization
      t.string :ed_utilization_detail
      t.boolean :high_risk_pregnancy
      t.string :high_risk_pregnancy_detail
      t.date :risk_factors_screened_on
      t.boolean :experiencing_homelessness
      t.string :experiencing_homelessness_detail
      t.boolean :at_risk_of_homelessness
      t.string :at_risk_of_homelessness_detail
      t.boolean :at_risk_of_nutritional_deficiency
      t.string :at_risk_of_nutritional_deficiency_detail
      t.text :health_and_risk_notes

      t.boolean :receives_snap
      t.boolean :receives_wic
      t.boolean :receives_csp
      t.boolean :receives_other
      t.string :receives_other_detail

      (1..10).each do |i|
        t.date "service_#{i}_added_on"
        t.string "service_#{i}_goals"
        t.string "service_#{i}_category"
        t.string "service_#{i}_flex_services"
        t.string "service_#{i}_units"
        t.string "service_#{i}_delivering_entity"
        t.string "service_#{i}_steps"
        t.string "service_#{i}_aco_plan"
      end

      t.string :gender
      t.string :gender_detail
      t.string :sexual_orientation
      t.string :sexual_orientation_detail
      t.jsonb :race
      t.string :race_detail
      t.string :primary_language
      t.string :education
      t.string :education_detail
      t.string :employment_status

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end

    create_table :health_flexible_service_follow_ups do |t|
      t.references :patient, index: true, null: false
      t.references :user, index: true, null: false
      t.date :completed_on
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.date :dob

      t.string :delivery_first_name
      t.string :delivery_last_name
      t.string :delivery_organization
      t.string :delivery_phone
      t.string :delivery_email
      t.string :reviewer_first_name
      t.string :reviewer_last_name
      t.string :reviewer_organization
      t.string :reviewer_phone
      t.string :reviewer_email

      t.text :services_completed
      t.text :goal_status
      t.boolean :additional_flex_services_requested
      t.text :additional_flex_services_requested_detail
      t.boolean :agreement_to_flex_services
      t.string :agreement_to_flex_services_detail
      t.boolean :aco_approved_flex_services
      t.string :aco_approved_flex_services_detail
      t.date :aco_approved_flex_services_on

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
  end
end
