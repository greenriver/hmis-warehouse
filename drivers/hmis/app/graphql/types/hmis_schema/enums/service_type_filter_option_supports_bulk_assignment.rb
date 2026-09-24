###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  # Yes/No rather than a boolean filter, so that service types that do not support bulk assignment
  # are filterable on their own.
  class HmisSchema::Enums::ServiceTypeFilterOptionSupportsBulkAssignment < Types::BaseEnum
    graphql_name 'ServiceTypeFilterOptionSupportsBulkAssignment'

    value 'YES', description: 'Yes'
    value 'NO', description: 'No'
  end
end
