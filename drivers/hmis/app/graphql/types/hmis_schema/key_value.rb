###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::KeyValue < Types::BaseObject
    skip_activity_log

    field :key, String, null: false
    field :value, String, null: true
  end
end
