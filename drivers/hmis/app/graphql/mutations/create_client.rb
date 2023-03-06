module Mutations
  class CreateClient < BaseMutation
    argument :input, Types::HmisSchema::ClientInput, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(input:)
      errors = HmisErrors::Errors.new
      errors.add :client_id, :not_allowed unless current_user.permission?(:can_edit_clients)
      return { errors: errors } if errors.any?

      client = Hmis::Hud::Client.new(
        data_source_id: hmis_user.data_source_id,
        user_id: hmis_user.user_id,
        personal_id: Hmis::Hud::Base.generate_uuid,
        **input.to_params,
      )

      return { errors: client.errors } unless client.valid?

      client.save!
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.delay.run!

      { client: client, errors: [] }
    end
  end
end
