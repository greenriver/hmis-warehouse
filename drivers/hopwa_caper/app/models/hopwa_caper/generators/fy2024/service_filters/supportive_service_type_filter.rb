###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::ServiceFilters
  SupportiveServiceTypeFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      scope.where(type_provided: codes)
    end

    def codes
      @codes ||= types.map { |type| lookup.fetch(type) }
    end

    def self.all
      [
        new(label: 'Adult Day Care and Personal Assistance', types: ['Adult day care and personal assistance']),
        new(label: 'Alcohol-Drug Abuse', types: ['Substance use services/treatment']),
        new(label: 'Child Care', types: ['Child care']),
        new(label: 'Case Management', types: ['Case management']),
        new(label: 'Education', types: ['Education']),
        new(label: 'Employment Assistance and Training', types: ['Employment and training services']),
        new(label: 'Health/Medical Services', types: ['Health/medical care']),
        new(label: 'Legal Services', types: ['Criminal justice/legal services']),
        new(label: 'Life Skills Management', types: ['Life skills training']),
        new(label: 'Meals/Nutritional Services', types: ['Food/meals/nutritional services']),
        new(label: 'Mental Health Services', types: ['Mental health care/counseling']),
        new(label: 'Outreach', types: ['Outreach and/or engagement']),
        new(label: 'Transportation', types: ['Transportation']),
        new(label: 'Any other type of HOPWA funded, HUD approved supportive service?', types: ['Other HOPWA funded service']),
      ].freeze
    end

    def self.supportive_service_codes
      all.flat_map(&:codes).uniq.freeze
    end

    private

    def lookup
      @lookup ||= HudHelper.util('2026').hopwa_services_options.invert
    end
  end
end
