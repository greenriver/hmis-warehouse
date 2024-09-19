###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  GenderFilter = Struct.new(:label, :code_names, keyword_init: true) do
    def id_map(name)
      HudUtility2024.gender_field_name_to_id.fetch(name)
    end

    def apply(scope)
      codes = code_names.map { |name| id_map(name) }
      quoted = SqlHelper.quote_sql_array(codes, type: :integer)
      scope.where("genders = #{quoted}")
    end

    def self.all
      filters = [
        new(label: 'Male', code_names: [:Man]),
        new(label: 'Female', code_names: [:Woman]),
        new(label: 'Gender Nonbinary', code_names: [:NonBinary]),
        new(label: 'Transgender Female', code_names: [:Transgender, :Woman]),
        new(label: 'Transgender Male', code_names: [:Transgender, :Man]),
      ]
      filters + [ExcludeFilter.new(label: 'Gender not Disclosed', filters: filters)]
    end
  end
end
