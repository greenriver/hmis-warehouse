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
      # TODO: check perm

      code = Hmis::ScanCardCode.with_deleted.find(id)
      return code unless code.deleted_at.present?

      code.deleted_at = nil
      code.deleted_by = nil
      code.save!

      { scan_card_code: code }
    end
  end
end
