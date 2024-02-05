###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteScanCardCode < CleanBaseMutation
    argument :id, ID, required: true

    field :scan_card_code, Types::HmisSchema::ScanCardCode, null: true

    def resolve(id:)
      code = Hmis::ScanCardCode.find(id)
      raise 'unauthorized' unless current_permission?(permission: :can_manage_scan_cards, entity: code.client)

      code.deleted_at = Time.current
      code.deleted_by = current_user
      code.save!

      { scan_card_code: code }
    end
  end
end
