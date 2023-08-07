class CreatePctpCareplans < ActiveRecord::Migration[6.1]
  def change
    create_table :pctp_careplans do |t|
      t.references :patient, null: false
      t.references :user, null: false

      t.string :name
      t.date :dob
      t.string :phone
      t.string :email
      t.string :mmis
      t.string :aco

      [:cc, :ccm, :pcp, :rn, :other_members].each do |label|
        [:name, :phone, :email].each do |kind|
          t.string "#{label}_#{kind}"
        end
      end

      t.string :overview
      t.string :scribe
      t.string :update_reason
      t.string :update_reason_other
      t.string :sex_at_birth
      t.string :sex_at_birth_other
      t.string :gender
      t.string :gender_other
      t.string :orientation
      t.string :orientation_other
      t.string :race
      t.string :ethnicity
      t.string :language
      t.string :contact
      t.string :contact_other

      t.string :strengths
      t.string :weaknesses
      t.string :interests
      t.string :choices
      t.string :care_goals
      t.string :personal_goals
      t.string :cultural_considerations

      t.string :accessibility_needs
      t.jsonb :accommodation_types
      t.jsonb :accessibility_equipment
      t.string :accessibility_equipment_notes
      t.date :accessibility_equipment_start
      t.date :accessibility_equipment_end

      t.string :goals

      t.string :service_summary

      t.string :contingency_plan
      t.string :crisis_plan
      t.string :additional_concerns

      t.date :patient_signed_on
      t.boolean :verbal_approval
      t.boolean :verbal_approval_followup

      t.bigint :reviewed_by_ccm_id
      t.date :reviewed_by_ccm_on

      t.boolean :offered_services_choice_care_planning
      t.boolean :offered_provider_choice_care_planning
      t.boolean :received_recommendations
      t.boolean :offered_services_choice_treatment_planning

      t.boolean :right_to_approve_pctp
      t.boolean :right_to_appeal
      t.boolean :right_to_change_cc
      t.boolean :right_to_change_bhcp
      t.boolean :right_to_complain
      t.boolean :right_to_ombudsman

      t.bigint :reviewed_by_rn_id
      t.date :reviewed_by_rn_on

      t.boolean :provided_to_patient
      t.date :sent_to_pcp_on
      t.bigint :sent_to_pcp_by_id

      t.timestamps
    end
  end
end
