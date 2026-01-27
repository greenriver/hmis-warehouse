# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::ServiceFilters
  SupportiveServiceTypeFilter = Struct.new(:id, :label, :types, keyword_init: true) do
    def apply(scope)
      scope.hud_services.where(type_provided: codes)
    end

    def codes
      types.map { |type| lookup.fetch(type) }
    end

    def self.all
      [
        new(id: :adult_day_care, label: 'Adult Day Care and Personal Assistance', types: ['Adult day care and personal assistance']),
        new(id: :alcohol_drug_abuse, label: 'Alcohol-Drug Abuse', types: ['Substance use services/treatment']),
        new(id: :child_care, label: 'Child Care', types: ['Child care']),
        new(id: :case_management, label: 'Case Management', types: ['Case management']),
        new(id: :education, label: 'Education', types: ['Education']),
        new(id: :employment_assistance, label: 'Employment Assistance and Training', types: ['Employment and training services']),
        new(id: :health_medical, label: 'Health/Medical Services', types: ['Health/medical care']),
        new(id: :legal_services, label: 'Legal Services', types: ['Criminal justice/legal services']),
        new(id: :life_skills, label: 'Life Skills Management', types: ['Life skills training']),
        new(id: :meals_nutritional, label: 'Meals/Nutritional Services', types: ['Food/meals/nutritional services']),
        new(id: :mental_health, label: 'Mental Health Services', types: ['Mental health care/counseling']),
        new(id: :outreach, label: 'Outreach', types: ['Outreach and/or engagement']),
        new(id: :transportation, label: 'Transportation', types: ['Transportation']),
        new(id: :other_supportive_service, label: 'Any other type of HOPWA funded, HUD approved supportive service?', types: ['Other HOPWA funded service']),
      ].freeze
    end

    def self.supportive_service_codes
      all.flat_map(&:codes).uniq.freeze
    end

    def self.case_management
      all.detect { |f| f.id == :case_management }
    end

    private

    def lookup
      @lookup ||= HudHelper.util('2026').hopwa_services_options.invert
    end
  end
end
