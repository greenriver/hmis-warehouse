###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AuditEventType < Types::BaseEnum
    graphql_name 'AuditEventType'

    value 'create'
    value 'update'
    value 'destroy'
  end
end
