module Mutations
  class DeleteClientImage < BaseMutation
    argument :client_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(client_id:)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)
      errors = []

      errors << CustomValidationError.new(:client_id, :not_found) unless client.present?

      if client.present?
        client.delete_image
        client = client.reload
      end

      return {
        client: client,
        errors: errors,
      }
    end
  end
end
