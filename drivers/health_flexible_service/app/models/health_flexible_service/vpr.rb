###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class Vpr < HealthBase
    include ArelHelper
    acts_as_paranoid

    phi_patient :id
    phi_attr :first_name, Phi::Name
    phi_attr :middle_name, Phi::Name
    phi_attr :last_name, Phi::Name
    phi_attr :dob, Phi::Date

    belongs_to :patient, class_name: 'Health::Patient', optional: true
    belongs_to :user, class_name: 'User', optional: true

    def set_defaults
      cha = patient.recent_cha_form
      ssm = patient.recent_ssm_form
      mmis_name = ::Health::Cp.sender.first&.mmis_enrollment_name

      self.planned_on = Date.current
      self.first_name = patient.client.FirstName
      self.middle_name = patient.client.MiddleName
      self.last_name = patient.client.LastName
      self.dob = patient.birthdate
      self.contact_type = :member
      self.phone = patient.most_recent_phone
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
      self.education = education_from(ssm.option_text_for(:education, ssm.education_score)) if ssm
      self.employment_status = employment_from(ssm.option_text_for(:employment, ssm.employment_score)) if ssm
      (1..HealthFlexibleService::Vpr.max_service_count).each do |i|
        self["service_#{i}_delivering_entity"] = mmis_name
      end
    end

    scope :category_in_range, ->(category, range) do
      a_t = arel_table
      query = nil

      (1..max_service_count).each do |i|
        service_category = "service_#{i}_category"
        service_date = "service_#{i}_added_on"

        query_part = a_t[service_category].eq(category).
          and(a_t[service_date].gteq(range.begin)).
          and(a_t[service_date].lteq(range.end))

        query = if query.nil?
          query_part
        else
          query = query.or(query_part)
        end
      end

      where(query)
    end

    private def education_from(value)
      case value
      when '[3] Has high school diploma/GED. (safe)'
        'High School Diploma or GED'
      end
    end

    private def employment_from(value)
      case value
      when '[1] No job. (in-crisis)'
        'Unemployed'
      when '[2] Temporary, part-time or seasonal; inadequate pay, no benefits. (vulnerable)'
        'Employed Part Time'
      when '[3] Employed full time; inadequate pay; few or no benefits. (safe)'
        'Employed Full-Time'
      when '[4] Employed full time with adequate pay and benefits. (stable)'
        'Employed Full-Time'
      when '[5] Maintains permanent employment with adequate income and benefits. (thriving)'
        'Employed Full-Time'
      end
    end

    private def gender_from(value)
      return unless value
      return 'Man' if value.start_with?('M')
      return 'Woman' if value.start_with?('F')
      return 'Transgender' if value.start_with?('Trans')
    end

    private def race_from(value)
      value&.map { |r| r&.gsub(/\[.\] /, '') }
    end

    private def language_from(value)
      value&.gsub(/\d+\. /, '')
    end

    def self.service_attributes
      (1..max_service_count + 1).map do |i|
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

    def self.max_service_count
      10
    end

    def self.available_contact_types
      {
        member: 'Member',
        other: 'Parent/Guardian/Caregiver',
      }.invert.freeze
    end

    def self.available_genders
      {
        'Man' => 'Man',
        'Woman' => 'Woman',
        'Non-Binary' => 'Non-Binary',
        'Transgender' => 'Transgender',
        'Prefer to self-describe (specify below)' => 'Prefer to self-describe (specify below)',
        'Prefer not to say' => 'Prefer not to say',
      }
    end

    def self.available_orientations
      {
        'Straight' => 'Straight',
        'Gay or Lesbian' => 'Gay or Lesbian',
        'Bisexual' => 'Bisexual',
        'Prefer to self-describe (specify below)' => 'Prefer to self-describe (specify below)',
        'Prefer not to say' => 'Prefer not to say',
      }
    end

    def self.available_races
      {
        'White' => 'White',
        'Hispanic, Latino, or Spanish' => 'Hispanic, Latino, or Spanish',
        'Black or African American' => 'Black or African American',
        'Asian' => 'Asian',
        'American Indian or Alaskan Native' => 'American Indian or Alaskan Native',
        'Middle Eastern or North African' => 'Middle Eastern or North African',
        'Native Hawaiian or Other Pacific Islander' => 'Native Hawaiian or Other Pacific Islander',
        'Some other race, ethnicity, or origin (Please specify)' => 'Some other race, ethnicity, or origin (Please specify)',
        'Prefer not to say' => 'Prefer not to say',
      }
    end

    def self.available_educations
      {
        'In grade school' => 'In grade school',
        'Did not finish high school' => 'Did not finish high school',
        'High School Diploma or GED' => 'High School Diploma or GED',
        'Associate Degree' => 'Associate Degree',
        'Vocational Degree' => 'Vocational Degree',
        'Some College' => 'Some College',
        'Bachelor’s Degree' => 'Bachelor’s Degree',
        'Graduate Degree' => 'Graduate Degree',
        'Other (Please specify)' => 'Other (Please specify)',
        'Prefer not to say' => 'Prefer not to say',
      }
    end

    def self.available_employments
      {
        'Employed Full-Time' => 'Employed Full-Time',
        'Employed Part Time' => 'Employed Part Time',
        'Student' => 'Student',
        'Not in Labor Force' => 'Not in Labor Force',
        'Unemployed' => 'Unemployed',
        'Home-maker' => 'Home-maker',
        'Self-employed' => 'Self-employed',
        'Prefer not to say' => 'Prefer not to say',
      }
    end

    def self.available_categories
      {
        'Pre-Tenancy Supports: Individual Supports' => 'Pre-Tenancy Supports: Individual Supports',
        'Pre-Tenancy Supports: Transitional Assistance' => 'Pre-Tenancy Supports: Transitional Assistance',
        'Home Modification' => 'Home Modification',
        'Nutritional Sustaining Supports' => 'Nutritional Sustaining Supports',
        'Tenancy Sustaining Supports' => 'Tenancy Sustaining Supports',
      }
    end
  end
end
