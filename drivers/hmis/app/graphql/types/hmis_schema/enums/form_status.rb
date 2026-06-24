###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::FormStatus < Types::BaseEnum
    graphql_name 'FormStatus'

    Hmis::Form::Definition::STATUSES.each do |status|
      value status, description: status.titleize
    end
  end
end
