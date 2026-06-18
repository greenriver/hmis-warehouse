###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCustomReferralStatus < Types::BaseObject
    # object is a Hmis::Ce::CustomReferralStatus
    field :id, ID, null: false
    field :key, String, null: false
    field :name, String, null: false
  end
end
