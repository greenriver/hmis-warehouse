###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ErrorGroup < Types::BaseObject
    field :id, ID, null: false
    field :class_name, String, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false
  end
end
