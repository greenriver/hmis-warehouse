###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class Need < HealthBase
    acts_as_paranoid

    belongs_to :careplan

    def domain_responses
      {
        'Health Needs (at least 2 must be active' => {
          accessibility: 'Accessibility requirements (DME)',
          advanced_directive: 'Advance directives status and preferences',
          functional: 'Functional status',
          guardianship: 'Guardianship status',
          immediate_care: 'Immediate care needs',
          medical: 'Medical needs',
          medication: 'Medication needs',
          mental_health: 'Mental health OR substance use',
        }.with_indifferent_access.invert,
        'Social Needs (at least 1 must be active)' => {
          housing: 'Housing and home environment',
          financial: 'Income and financial supports',
          legal: 'Legal status',
          personal_goal: 'Self-identified personal goals',
          social_supports: 'Self-care and social supports, social services and care coordination',
          communication: 'Communication of concerns',
          education: 'Education needs',
          employment_goal: 'Employment goals',
          nutrition: 'Food security, nutrition, wellness, and exercise',
          abuse: 'Risk factors for abuse or neglect',
          housing_insecurity: 'Housing insecurity',
          food_insecurity: 'Food insecurity',
          economic_stress: 'Economic stress (lack of utilities, heat and/or internet)',
          transportation: 'Lack of transportation',
          violence: 'Experience of violence',
          employment: 'Employment supports (age 21-45)',
          isolation: 'Social isolation (age 45+)',
          other: 'Other (Please specify)',
        }.with_indifferent_access.invert,
      }
    end

    def translate_domain_response(key)
      @traslate_domain_response ||= domain_responses.values.map { |h| h.map { |k, v| [v, k] } }.flatten(1).to_h.with_indifferent_access
      @traslate_domain_response[key]
    end

    def status_responses
      {
        active: 'Active',
        referred: 'Referred Out',
        declined: 'Person Declined',
        deferred: 'Deferred',
      }.with_indifferent_access.invert
    end

    def translate_status_response(key)
      status_responses.invert[key]
    end
  end
end
