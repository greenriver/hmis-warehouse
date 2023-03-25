###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ValidationType < Types::BaseEnum
    graphql_name 'ValidationType'

    value 'required'
    value 'invalid'
    value 'information'
    value 'not_found'
    value 'not_allowed'
    value 'out_of_range'
    value 'server_error'
    value 'data_not_collected'
  end
end
