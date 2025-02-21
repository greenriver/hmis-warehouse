###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::LastContact < Types::BaseObject
    skip_activity_log

    field :contact_date, GraphQL::Types::ISO8601Date, null: false
    field :contact_type, HmisSchema::Enums::LastContactType, null: false
  end
end
