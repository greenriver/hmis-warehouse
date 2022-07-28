###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::SSNDataQuality < Types::BaseEnum
    description 'HUD SSN Data Quality'
    graphql_name 'SSNDataQuality'

    value 'SSN_FULL', 'Full SSN Reported', value: 1
    value 'SSN_PARTIAL', 'Approximate or partial  SSN reported', value: 2
    value 'SSN_UNKNOWN', 'Client doesn\'t know', value: 8
    value 'SSN_REFUSED', 'Client refused', value: 9
    value 'SSN_NOT_COLLECTED', 'Data not collected', value: 99
  end
end
