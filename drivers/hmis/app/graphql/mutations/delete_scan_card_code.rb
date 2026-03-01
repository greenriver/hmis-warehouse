###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteScanCardCode < CleanBaseMutation
    argument :id, ID, required: true

    field :scan_card_code, Types::HmisSchema::ScanCardCode, null: true

    def resolve(id:)
      code = Hmis::ScanCardCode.find(id)
      access_denied! unless policy_for(code.client, policy_type: :hmis_client).can_manage_scan_cards?

      code.deleted_at = Time.current
      code.deleted_by = current_user
      code.save!

      { scan_card_code: code }
    end
  end
end
