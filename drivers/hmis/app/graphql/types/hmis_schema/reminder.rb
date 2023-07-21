###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Reminder < Types::BaseObject
    field :id, ID, null: false
    field :topic, HmisSchema::Enums::ReminderTopic, null: false
    field :due_date, GraphQL::Types::ISO8601Date, null: false
    field :description, String, null: false
    field :enrollment_id, ID, null: false

    def id
      "#{object.enrollment_id}.#{object.topic}"
    end
  end
end
