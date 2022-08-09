###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ValidationError < Types::BaseObject
    field :attribute, String, null: true
    field :message, String, null: false
    field :full_message, String, null: true
    field :type, String, null: false
    field :options, JsonObject, null: true
  end
end
