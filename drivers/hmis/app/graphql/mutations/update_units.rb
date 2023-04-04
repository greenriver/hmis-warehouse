###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateUnits < BaseMutation
    argument :inventory_id, ID, required: true
    argument :unit_ids, [ID], required: true
    argument :name, String, required: false

    field :units, [Types::HmisSchema::Unit], null: false

    def resolve(inventory_id:, unit_ids:, name:)
      inventory = Hmis::Hud::Inventory.viewable_by(current_user).find_by(id: inventory_id)
      return { units: [], errors: [HmisErrors::Error.new(:inventory_id, :not_found)] } unless inventory.present?
      return { units: [], errors: [HmisErrors::Error.new(:inventory_id, :not_allowed)] } unless current_user.permissions_for?(inventory, :can_edit_project_details)

      units = inventory.units.where(id: unit_ids)
      units.update_all(name: name, user_id: hmis_user.user_id, updated_at: Time.now)

      { units: units, errors: [] }
    end
  end
end
