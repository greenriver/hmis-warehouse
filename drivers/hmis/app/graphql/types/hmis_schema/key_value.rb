###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::KeyValue < Types::BaseObject
    field :key, String, null: false
    field :value, String, null: true
  end
end
