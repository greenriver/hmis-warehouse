module Mutations
  class UpdateClientImage < BaseMutation
    argument :client_id, ID, required: true
    argument :image_blob_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:, image_blob_id:)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)

      errors = HmisErrors::Errors.new
      errors.add :client_id, :not_found unless client.present?
      errors.add :client_id, :not_allowed if client.present? && !current_user.permission?(:can_edit_clients)
      return { errors: errors } if errors.any?

      client.image_blob_id = image_blob_id
      client.save!
      client = client.reload

      {
        client: client,
        errors: [],
      }
    end
  end
end
