###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  EthnicityFilter = Struct.new(:label, :code_name, keyword_init: true) do
    def apply(scope)
      code = HudHelper.util('2026').race_field_name_to_id.fetch(code_name)
      # Hisp and any other race/ethnicity
      scope.where.contains(races: [code])
    end

    def self.all
      [
        new(label: 'Total Hispanic', code_name: :HispanicLatinaeo),
      ]
    end
  end
end
