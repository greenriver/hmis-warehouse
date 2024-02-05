#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class HmisSchema::Enums::ClientAlertPriorityLevel < Types::BaseEnum
    graphql_name 'ClientAlertPriorityLevel'

    Hmis::ClientAlert::PRIORITY_LEVELS.each_with_index do |level, index|
      value level, description: "#{index + 1} - #{level.titleize}"
    end
  end
end
