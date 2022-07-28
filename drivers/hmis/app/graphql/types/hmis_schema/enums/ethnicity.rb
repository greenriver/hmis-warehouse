###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Ethnicity < Types::BaseEnum
    description 'HUD Ethnicity'
    graphql_name 'Ethnicity'

    value 'ETHNICITY_NON_HISPANIC', 'Non-Hispanic/Non-Latin(a)(o)(x)', value: 0
    value 'ETHNICITY_HISPANIC', 'Hispanic/Latin(a)(o)(x)', value: 1
    value 'ETHNICITY_UNKNOWN', 'Client doesn\'t know', value: 8
    value 'ETHNICITY_REFUSED', 'Client refused', value: 9
    value 'ETHNICITY_NOT_COLLECTED', 'Data not collected', value: 99
  end
end
