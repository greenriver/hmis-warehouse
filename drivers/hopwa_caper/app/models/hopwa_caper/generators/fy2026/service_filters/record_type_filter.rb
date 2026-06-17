###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper::Generators::Fy2026::ServiceFilters
  RecordTypeFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      scope.hud_services.where(record_type: codes)
    end

    def codes
      types.map do |type|
        HudHelper.util('2026').record_types.invert.fetch(type)
      end
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
