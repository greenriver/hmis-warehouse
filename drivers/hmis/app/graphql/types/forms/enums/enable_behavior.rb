###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::EnableBehavior < Types::BaseEnum
    graphql_name 'EnableBehavior'
    value 'ANY'
    value 'ALL'
  end
end
