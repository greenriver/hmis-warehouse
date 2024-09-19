###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  RaceFilter = Struct.new(:label, :code_names, keyword_init: true) do
    def id_map(name)
      HudUtility2024.race_field_name_to_id.fetch(name)
    end

    def apply(scope)
      race_codes = code_names.map { |name| id_map(name) }
      hispanic_latino_code = id_map(:HispanicLatinaeo)

      # get the race with or without ethnicity
      scope.where(
        "races = #{SqlHelper.quote_sql_array(race_codes, type: :integer)} OR races = #{SqlHelper.quote_sql_array(race_codes + [hispanic_latino_code], type: :integer)}::integer[]",
      )
    end

    def self.all
      filters = [
        new(label: 'Asian', code_names: [:Asian]),
        new(label: 'Asian & White', code_names: [:Asian, :White]),
        new(label: 'Black/African American', code_names: [:BlackAfAmerican]),
        new(label: 'Black/African American & White', code_names: [:BlackAfAmerican, :White]),
        new(label: 'American Indian/Alaskan Native', code_names: [:AmIndAKNative]),
        new(label: 'American Indian/Alaskan Native & Black/African American', code_names: [:AmIndAKNative, :BlackAfAmerican]),
        new(label: 'American Indian/Alaskan Native & White', code_names: [:AmIndAKNative, :White]),
        new(label: 'Native Hawaiian/Other Pacific Islander', code_names: [:NativeHIPacific]),
        new(label: 'White', code_names: [:White]),
      ]
      other_filter = ExcludeFilter.new(label: 'Other Multi-Racial', filters: filters)
      filters + [other_filter]
    end
  end
end
