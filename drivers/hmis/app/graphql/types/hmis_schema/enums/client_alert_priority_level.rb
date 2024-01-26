#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class HmisSchema::Enums::ClientAlertPriorityLevel < Types::BaseEnum
    graphql_name 'ClientAlertPriorityLevel'

    Hmis::AlertPriority::PRIORITY_LEVELS.each do |topic|
      value topic
    end
  end
end
