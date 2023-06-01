###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AgeRange < Types::BaseEnum
    description 'HUD Age Ranges'
    graphql_name 'AgeRange'

    value 'Under5', 'Under 5', value: [0..4]
    value 'Ages5to12', '5-12', value: [5..12]
    value 'Ages13to17', '13-17', value: [13..17]
    value 'Ages18to24', '18-24', value: [18..24]
    value 'Ages25to34', '25-34', value: [25..34]
    value 'Ages35to44', '35-44', value: [35..44]
    value 'Ages45to54', '45-54', value: [45..54]
    value 'Ages55to61', '55-61', value: [55..61]
    value 'Ages55to64', '55-64', value: [55..64]
    value 'Age62Plus', '62+', value: [62..Float::INFINITY]
    value 'Age65Plus', '65+', value: [65..Float::INFINITY]
  end
end
