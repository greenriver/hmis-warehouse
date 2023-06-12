###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class CareGoal < HealthBase
    belongs_to :careplan

    def domain_responses
      {
        accessibility: 'Accessibility requirements',
        advanced_directives: 'Advance directives status and preferences',
        communication: 'Communication of concerns',
        education: 'Education needs',
        employment: 'Employment goals',
        food: 'Food insecurity, nutrition, wellness, and exercise',
        functional: 'Functional status',
        guardian: 'Guardianship status',
        housing: 'Housing and home environment',
        immediate_care: 'Immediate care needs',
        financial: 'Income and financial supports',
        legal: 'Legal status',
        medical: 'Medical needs',
        medication: 'Medication needs',
        mental_health: 'Mental health OR substance use',
        self_identified: 'Self-identified personal goals',
        social: 'Self-care and social supports, Social services and care coordination',
        abuse: 'Risk factors for abuse or neglect',
        other: 'Other (Please specify)',
      }.with_indifferent_access.invert
    end

    def status_responses
      {
        new: 'New',
        unmet: 'Active - Not Met',
        partial: 'Active - Partially Met',
        completed: 'Completed',
        revised: 'Revised',
        discontinued: 'Discontinued',
        deferred: 'Deferred',
      }.with_indifferent_access.invert
    end

    def source_responses
      {
        assessment: 'Comprehensive Assessment',
        member: 'Member Identified',
        screener: 'Screening Tool (Please Specify)',
        other: 'Other – Not Listed (Please Specify)',
      }.with_indifferent_access.invert
    end

    def priority_responses
      {
        high: 'High',
        medium: 'Medium',
        low: 'Low',
      }.with_indifferent_access.invert
    end
  end
end
