###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::VeteranStatus < Types::BaseEnum
    description 'HUD Veteran Status'
    graphql_name 'VeteranStatus'

    value 'VETERAN_STATUS_NO', 'No', value: 0
    value 'VETERAN_STATUS_YES', 'Yes', value: 1
    value 'VETERAN_STATUS_UNKNOWN', 'Client doesn\'t know', value: 8
    value 'VETERAN_STATUS_REFUSED', 'Client refused', value: 9
    value 'VETERAN_STATUS_NOT_COLLECTED', 'Data not collected', value: 99
  end
end
