###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::ServiceDetailType < Types::BaseEnum
    graphql_name 'ServiceDetailType'

    value 'CLIENT'
    value 'BULK'
  end
end
