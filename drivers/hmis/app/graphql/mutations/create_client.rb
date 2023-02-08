module Mutations
  class CreateClient < BaseMutation
    argument :input, Types::HmisSchema::ClientInput, required: true

    field :client, Types::HmisSchema::Client, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      client = Hmis::Hud::Client.new(
        data_source_id: hmis_user.data_source_id,
        user_id: hmis_user.user_id,
        personal_id: Hmis::Hud::Base.generate_uuid,
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
