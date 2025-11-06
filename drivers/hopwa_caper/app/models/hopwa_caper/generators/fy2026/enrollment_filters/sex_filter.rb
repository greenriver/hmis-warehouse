###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  SexFilter = Struct.new(:label, :code_names, keyword_init: true) do
    def id_map(name)
      HudHelper.util('2026').gender_field_name_to_id.fetch(name)
    end

    def apply(scope)
      codes = code_names.map { |name| id_map(name) }
      quoted = SqlHelper.quote_sql_array(codes, type: :integer)
      scope.where("genders = #{quoted}")
    end

    def self.all
      filters = [
        new(label: 'Female', code_names: [:Woman]),
        new(label: 'Male', code_names: [:Man]),
      ]

      filters + [ExcludeFilter.new(label: 'Sex not reported', filters: filters)]
    end
  end
end
