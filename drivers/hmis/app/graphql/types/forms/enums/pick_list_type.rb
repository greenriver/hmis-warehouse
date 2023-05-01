###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    value 'GEOCODE'
    value 'STATE'
    value 'PRIOR_LIVING_SITUATION'
    value 'CURRENT_LIVING_SITUATION'
    value 'DESTINATION'
    value 'AVAILABLE_UNITS'
    value 'SERVICE_TYPE'
    value 'SUB_TYPE_PROVIDED_3'
    value 'SUB_TYPE_PROVIDED_4'
    value 'SUB_TYPE_PROVIDED_5'
    value 'REFERRAL_OUTCOME'
    value 'AVAILABLE_FILE_TYPES'
    value 'CLIENT_ENROLLMENTS'
  end
end
