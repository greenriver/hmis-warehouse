module HealthFlexibleServices
  class Vpr < HealthBase
    include ArelHelper
    acts_as_paranoid

    phi_patient :id
    phi_attr :first_name, Phi::Name
    phi_attr :middle_name, Phi::Name
    phi_attr :last_name, Phi::Name
    phi_attr :dob, Phi::Date

    belongs_to :patient, class_name: 'Health::Patient'
    belongs_to :user, class_name: 'User'

    def set_defaults
      cha = patient.recent_cha_form
      ssm = patient.recent_ssm_form
      self.planned_on = Date.current
      self.first_name = patient.client.FirstName
      self.middle_name = patient.client.MiddleName
      self.last_name = patient.client.LastName
      self.dob = patient.birthdate
      self.contact_type = :member
      # self.phone = patient.phone
      self.email = patient.email
      self.main_contact_first_name = user.first_name
      self.main_contact_last_name = user.last_name
      self.main_contact_organization = user.agency&.name
      self.main_contact_phone = user.phone
      self.main_contact_email = user.email
      self.reviewer_first_name = user.first_name
      self.reviewer_last_name = user.last_name
      self.reviewer_organization = user.agency&.name
      self.reviewer_phone = user.phone
      self.reviewer_email = user.email
      self.representative_first_name = user.first_name
      self.representative_last_name = user.last_name
      self.representative_organization = user.agency&.name
      self.representative_phone = user.phone
      self.representative_email = user.email
      self.member_agrees_to_plan = true
      self.aco_approved = true
      self.aco_approved_on = Date.current
      self.health_needs_screened_on = Date.current
      self.risk_factors_screened_on = Date.current
      self.gender = gender_from(patient.gender)
      self.race = race_from(cha.answer('b_q2')) if cha
      self.primary_language = language_from(cha.answer('b_q3')) if cha
      self.education = ssm.option_text_for(:education, ssm.education_score) if ssm
      self.employment_status = ssm.option_text_for(:employment, ssm.employment_score) if ssm
    end

    def gender_from(value)
      return unless value
      return 'Male' if value.start_with?('M')
      return 'Female' if value.start_with?('F')
      return 'Transgender' if value.start_with?('Trans')
    end

    def race_from(value)
      value&.gsub(/\[.\] /, '')
    end

    def language_from(value)
      value&.gsub(/\[.\] /, '')
    end

    def self.service_attributes
      (1..10).map do |i|
        [
          "service_#{i}_added_on",
          "service_#{i}_goals",
          "service_#{i}_category",
          "service_#{i}_flex_services",
          "service_#{i}_units",
          "service_#{i}_delivering_entity",
          "service_#{i}_steps",
          "service_#{i}_aco_plan",
        ]
      end.flatten
    end

    def self.available_contact_types
      {
        member: 'Member',
        other: 'Parent/Guardian/Caregiver',
      }.invert.freeze
    end
  end
end
