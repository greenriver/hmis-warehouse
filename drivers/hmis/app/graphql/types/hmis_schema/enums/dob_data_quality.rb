###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::DOBDataQuality < Types::BaseEnum
    description 'HUD DOB Data Quality'
    graphql_name 'DOBDataQuality'

    value 'DOB_FULL', 'Full DOB Reported', value: 1
    value 'DOB_PARTIAL', 'Approximate or partial  DOB reported', value: 2
    value 'DOB_UNKNOWN', 'Client doesn\'t know', value: 8
    value 'DOB_REFUSED', 'Client refused', value: 9
    value 'DOB_NOT_COLLECTED', 'Data not collected', value: 99
  end
end
