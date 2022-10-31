###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::PickListType < Types::BaseEnum
    graphql_name 'PickListType'

    value 'COC'
    value 'PROJECT'
    value 'ORGANIZATION'
    # value 'GEOCODE'
    value 'PRIOR_LIVING_SITUATION'
    value 'CURRENT_LIVING_SITUATION'
  end
end
