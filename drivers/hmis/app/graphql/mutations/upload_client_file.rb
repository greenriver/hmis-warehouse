# ! This is not included in the schema, but it does define the logic for creating a new file, so leaving in place as reference for the file processor

module Mutations
  class UploadClientFile < BaseMutation
    argument :client_id, ID, required: true
    argument :enrollment_id, ID, required: false
    argument :file_blob_id, ID, required: true
    argument :file_tags, [ID], required: false
    argument :effective_date, GraphQL::Types::ISO8601Date, required: false
    argument :expiration_date, GraphQL::Types::ISO8601Date, required: false
    argument :confidential, Boolean, required: false
    argument :name, String, required: false

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:, enrollment_id: nil, file_blob_id:, tags: [], **input)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)

      errors = HmisErrors::Errors.new
      errors.add :client_id, :not_found unless client.present?
      errors.add :enrollment_id, :not_found if enrollment_id.present? && enrollment.nil?
      errors.add :client_id, :not_allowed if client.present? && !current_user.can_edit_clients_for?(client)
      errors.add :enrollment_id, :not_allowed if enrollment.present? && !current_user.can_edit_enrollments_for?(enrollment)
      return { errors: errors } if errors.any?

      blob = ActiveStorage::Blob.find_by(id: file_blob_id)

      if blob
        file = Hmis::File.new(
          client_id: client_id,
          enrollment_id: enrollment_id,
          user_id: current_user.id,
          name: blob.filename,
          visible_in_window: false,
          **input,
        )
        file.tag_list.add(tags)
        file.client_file.attach(blob)
        file.save!
      end

      client = client.reload

      {
        client: client,
        errors: [],
      }
    end
  end
end
