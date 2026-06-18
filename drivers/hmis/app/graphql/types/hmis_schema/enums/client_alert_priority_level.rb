###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ClientAlertPriorityLevel < Types::BaseEnum
    graphql_name 'ClientAlertPriorityLevel'

    Hmis::ClientAlert::PRIORITY_LEVELS.each_with_index do |level, index|
      value level, description: "#{index + 1} - #{level.titleize}"
    end
  end
end
