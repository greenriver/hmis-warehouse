###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AgeRange < Types::BaseEnum
    description 'HUD Age Ranges'
    graphql_name 'AgeRange'

    [
      { code: 'Under5', description: 'Under 5' },
      { code: 'Ages5to12', description: '5-12' },
      { code: 'Ages13to17', description: '13-17' },
      { code: 'Ages18to24', description: '18-24' },
      { code: 'Ages25to34', description: '25-34' },
      { code: 'Ages35to44', description: '35-44' },
      { code: 'Ages45to54', description: '45-54' },
      { code: 'Ages55to61', description: '55-61' },
      { code: 'Ages55to64', description: '55-64' },
      { code: 'Age62Plus', description: '62+' },
      { code: 'Age65Plus', description: '65+' },
    ].map do |option|
      value option[:code], option[:description], value: HudUtility2024.age_range[option[:description]]
    end
  end
end
