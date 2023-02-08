module Mutations
  class UpdateClientImage < BaseMutation
    argument :client_id, ID, required: true
    argument :image_blob_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:, image_blob_id:)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)
      errors = []

      errors << HmisErrors::Error.new(:client_id, :not_found) unless client.present?

      if client.present?
        client.image_blob_id = image_blob_id
        client.save!
        client = client.reload
      end

      return {
        client: client,
        errors: errors,
      }
    end
  end
end
