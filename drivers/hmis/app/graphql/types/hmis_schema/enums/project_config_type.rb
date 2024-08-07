# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class HmisSchema::Enums::ProjectConfigType < Types::BaseEnum
    graphql_name 'ProjectConfigType'

    value 'AUTO_EXIT', description: 'Auto Exit'
    value 'AUTO_ENTER', description: 'Auto Enter'
    value 'STAFF_ASSIGNMENT', description: 'Staff Assignment'
  end
end
