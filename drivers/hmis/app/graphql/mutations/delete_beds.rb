module Mutations
  class DeleteBeds < BaseMutation
    argument :inventory_id, ID, required: true
    argument :bed_ids, [ID], required: true

    field :inventory, Types::HmisSchema::Inventory, null: true

    def resolve(inventory_id:, bed_ids:)
      inventory = Hmis::Hud::Inventory.viewable_by(current_user).find_by(id: inventory_id)
      return { inventory: nil, errors: [HmisErrors::Error.new(:inventory_id, :not_found)] } unless inventory.present?
      return { inventory: nil, errors: [HmisErrors::Error.new(:inventory_id, :not_allowed)] } unless current_user.permissions_for?(inventory, :can_edit_project_details)

      return { inventory => inventory, errors: [] } unless bed_ids.any?

      inventory.beds.where(id: bed_ids).destroy_all

      { inventory => inventory, errors: [] }
    end
  end
end
