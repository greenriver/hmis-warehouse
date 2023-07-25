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
    field :due_date, GraphQL::Types::ISO8601Date, null: true
    field :client, HmisSchema::Client, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :overdue, Boolean, null: false

    def client
      object.enrollment.client
    end

    def overdue
      !!object.overdue
    end
  end
end
