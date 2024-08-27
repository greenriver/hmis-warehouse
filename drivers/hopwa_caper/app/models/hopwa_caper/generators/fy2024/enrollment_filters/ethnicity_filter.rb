###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  EthnicityFilter = Struct.new(:label, :code_name, keyword_init: true) do
    def apply(scope)
      code = HudUtility2024.race_field_name_to_id.fetch(code_name)
      # Hisp and any other race/ethnicity
      scope.where("races @> #{SqlHelper.quote_sql_array([code], type: :integer)}")
    end

    def self.all
      [
        new(label: 'Total Hispanic or Latinx', code_name: :HispanicLatinaeo),
      ]
    end
  end
end
