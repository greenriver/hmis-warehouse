###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::InputSize < Types::BaseEnum
    graphql_name 'InputSize'
    value 'XSMALL'
    value 'SMALL'
    value 'MEDIUM'
    value 'LARGE'
  end
end
