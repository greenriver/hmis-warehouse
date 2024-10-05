###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::ServiceFilters
  RecordTypeFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      scope.where(record_type: codes)
    end

    def codes
      types.map do |type|
        HudUtility2024.record_types.invert.fetch(type)
      end
    end

    def self.any_hopwa_assistance
      new(
        label: 'Any HOPWA Assistance',
        types: [
          'HOPWA Financial Assistance',
          'HOPWA Service',
        ],
      )
    end

    def self.hopwa_financial_assistance
      new(
        label: 'HOPWA Financial Assistance',
        types: ['HOPWA Financial Assistance'],
      )
    end

    def self.hopwa_service
      new(
        label: 'HOPWA Service',
        types: ['HOPWA Service'],
      )
    end
  end
end
