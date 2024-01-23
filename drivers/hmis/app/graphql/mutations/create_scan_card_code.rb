###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateScanCardCode < CleanBaseMutation
    argument :client_id, ID, required: true

    field :scan_card_code, Types::HmisSchema::ScanCardCode, null: true

    def resolve(client_id:)
      # TODO: check perm
      client = Hmis::Hud::Client.viewable_by(current_user).find(client_id)

      scan_card_code = Hmis::ScanCardCode.new(client: client, created_by: current_user)
      scan_card_code.assign_code
      scan_card_code.save!

      { scan_card_code: scan_card_code }
    end
  end
end
