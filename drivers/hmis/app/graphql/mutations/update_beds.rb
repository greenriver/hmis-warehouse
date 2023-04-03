###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateBeds < BaseMutation
    argument :inventory_id, ID, required: true
    argument :bed_ids, [ID], required: true
    argument :name, String, required: false
    argument :gender, String, required: false
    argument :unit, ID, required: false

    field :beds, [Types::HmisSchema::Bed], null: false

    def resolve(inventory_id:, bed_ids:, name: nil, gender: nil, unit: nil)
      inventory = Hmis::Hud::Inventory.viewable_by(current_user).find_by(id: inventory_id)
      return { beds: [], errors: [HmisErrors::Error.new(:inventory_id, :not_found)] } unless inventory.present?
      return { beds: [], errors: [HmisErrors::Error.new(:inventory_id, :not_allowed)] } unless current_user.permissions_for?(inventory, :can_edit_project_details)

      beds = inventory.beds.where(id: bed_ids)

      common = { user_id: hmis_user.user_id, updated_at: Time.now }
      beds.update_all(gender: gender, name: name, **common)
      beds.update_all(unit_id: unit.to_i, **common) if unit.present?

      { beds: beds, errors: [] }
    end
  end
end
