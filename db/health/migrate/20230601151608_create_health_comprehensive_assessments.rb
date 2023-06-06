class CreateHealthComprehensiveAssessments < ActiveRecord::Migration[6.1]
  def change
    create_table :hca_assessments do |t|
      t.references :patient, null: false
      t.references :user, null: false
      t.date :completed_on

      t.string :name
      t.string :pronouns
      t.string :pronouns_other
      t.date :dob
      t.string :update_reason
      t.string :update_reason_other
      t.string :phone
      t.string :email
      t.string :contact
      t.string :contact_other
      t.string :message_ok
      t.string :internet_access

      t.string :race
      t.string :ethnicity
      t.string :language
      t.string :disabled
      t.string :orientation
      t.string :orientation_other
      t.string :sex_at_birth
      t.string :sex_at_birth_other
      t.string :gender
      t.string :gender_other

      t.jsonb :funders

      [:pcp, :hh, :psych, :therapist, :case_manager, :specialist, :guardian, :rep_payee, :social_support, :cbfs,
        :housing, :day, :job, :peer_support, :dta, :va, :probation, :other_provider].each do |type_key|
        [:provider, :address, :phone, :notes].each do |col_name|
          t.string "#{type_key}_#{col_name}"
        end
      end

      [:hip_fracture, :other_fracture, :chronic_pain, :alzheimers, :dementia, :stroke, :parkinsons, :hypertension,
        :cad, :chf, :copd, :asthma, :apnea, :anxiety, :bipolar, :depression, :schizophrenia, :cancer, :diabetes,
        :arthritis, :ckd, :liver, :transplant, :weight, :other_condition].each do |condition|
        t.string "#{condition}_status"
        t.string "#{condition}_notes"
      end

      t.string :general_health_condition
      t.string :general_health_pain
      t.string :general_health_comments

      t.string :medication_adherence
      t.string :medication_adherence_notes

      t.jsonb :can_communicate_about
      t.string :can_communicate_notes

      t.jsonb :assessed_needs
      t.string :assessed_needs_notes

      t.string :strengths
      t.string :weaknesses
      t.string :interests
      t.string :choices
      t.string :personal_goals
      t.string :cultural_considerations

      t.string :substance_use
      t.string :cigarette_use
      t.string :smokeless_use
      t.string :alcohol_use
      t.string :alcohol_drinks
      t.string :alcohol_driving

      t.string :sud_treatment_efficacy
      t.jsonb :sud_treatment_sources
      t.string :sud_treatment_sources_other

      t.string :preferred_mode
      t.string :communicate_in_english

      t.string :accessibility_equipment
      t.string :accessibility_equipment_notes
      t.date :accessibility_equipment_start
      t.date :accessibility_equipment_end

      t.string :has_supports
      t.jsonb :supports
      t.jsonb :supports_other
      t.string :social_supports

      t.integer :physical_abuse_frequency
      t.integer :verbal_abuse
      t.integer :threat_frequency
      t.integer :scream_or_curse_frequency
      t.string :abuse_risk_notes

      t.string :advanced_directive
      t.string :directive_type
      t.string :directive_type_other
      t.string :develop_directive

      t.string :employment_status
      t.string :employment_status_other

      t.string :has_legal_involvement
      t.jsonb :legal_involvements
      t.string :legal_involvements_other

      t.string :education_level
      t.string :education_level_other
      t.integer :grade_level

      t.jsonb :financial_supports
      t.string :financial_supports_other

      t.timestamps
    end

    create_table :hca_medications do |t|
      t.references :assessment
      t.string :medication
      t.string :dosage
      t.string :side_effects

      t.timestamps
    end

    create_table :hca_sud_treatments do |t|
      t.references :assessment
      t.string :service_type
      t.string :service_dates
      t.string :reason
      t.string :provider_name
      t.string :inpatient
      t.string :completed

      t.timestamps
    end
  end
end
