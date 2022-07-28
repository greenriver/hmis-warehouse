###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::NameDataQuality < Types::BaseEnum
    description 'HUD Name Data Quality'
    graphql_name 'NameDataQuality'

    value 'NAME_FULL', 'Full name reported', value: 1
    value 'NAME_PARTIAL', 'Partial, street name, or code name reported', value: 2
    value 'NAME_UNKNOWN', 'Client doesn\'t know', value: 8
    value 'NAME_REFUSED', 'Client refused', value: 9
    value 'NAME_NOT_COLLECTED', 'Data not collected', value: 99
  end
end
