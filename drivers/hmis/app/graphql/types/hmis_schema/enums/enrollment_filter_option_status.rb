###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::EnrollmentFilterOptionStatus < Types::BaseEnum
    graphql_name 'EnrollmentFilterOptionStatus'

    value 'EXITED', description: 'Exited'
    value 'ACTIVE', description: 'Active'
    value 'INCOMPLETE', description: 'Incomplete'
  end
end
