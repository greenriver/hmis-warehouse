###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ReminderTopic < Types::BaseEnum
    graphql_name 'ReminderTopic'

    Hmis::Reminders::TOPICS.each do |topic|
      value topic
    end
  end
end
