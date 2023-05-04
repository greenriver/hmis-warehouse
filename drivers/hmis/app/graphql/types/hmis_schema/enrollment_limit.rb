###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::EnrollmentLimit < Types::BaseEnum
    graphql_name 'EnrollmentLimit'
    value 'WIP_ONLY'
    value 'NON_WIP_ONLY'
  end
end
