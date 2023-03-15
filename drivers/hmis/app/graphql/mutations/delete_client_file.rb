module Mutations
  class DeleteClientFile < BaseMutation
    argument :file_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(file_id:)
      file = Hmis::File.find_by(id: file_id)

      errors = HmisErrors::Errors.new
      errors.add :file_id, :not_found unless file.present?
      errors.add :file_id, :not_allowed if file.present? && !current_user.can_edit_clients_for?(file.client)
      return { errors: errors } if errors.any?

      file.destroy!

      {
        client: file.client,
        errors: [],
      }
    end
  end
end
