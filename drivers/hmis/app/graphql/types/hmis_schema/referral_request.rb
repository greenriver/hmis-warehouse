###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ReferralRequest < Types::BaseObject
    field :id, ID, null: false
    field :requested_date, String, null: false, method: :requested_on
    field :unit_type, ID, null: false
    field :estimated_date_needed, String, null: false, method: :needed_by
    field :requestor_name, String, null: false
    field :requestor_phone, String, null: false
    field :requestor_email_address, String, null: false, method: :requestor_email
  end
end
