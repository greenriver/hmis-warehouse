module Mutations
  class CreateClient < BaseMutation
    argument :input, Types::HmisSchema::ClientInput, required: true

    field :client, Types::HmisSchema::Client, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      user = hmis_user

      client = Hmis::Hud::Client.new(
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        personal_id: SecureRandom.uuid.gsub(/-/, ''),
        date_updated: DateTime.current,
        date_created: DateTime.current,
        **input.to_params,
      )

      errors = []

      if client.valid?
        client.save!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.delay.run!
      else
        errors = client.errors
        client = nil
      end

      {
        client: client,
        errors: errors,
      }
    end
  end
end
