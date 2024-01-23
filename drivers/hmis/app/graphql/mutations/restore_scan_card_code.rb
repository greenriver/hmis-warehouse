###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class RestoreScanCardCode < CleanBaseMutation
    argument :id, ID, required: true

    field :scan_card_code, Types::HmisSchema::ScanCardCode, null: true

    def resolve(id:)
      code = Hmis::ScanCardCode.with_deleted.find(id)
      raise 'unauthorized' unless current_permission?(permission: :can_manage_scan_cards, entity: code.client)

      return code unless code.deleted_at.present?

      code.deleted_at = nil
      code.deleted_by = nil
      code.save!

      { scan_card_code: code }
    end
  end
end
