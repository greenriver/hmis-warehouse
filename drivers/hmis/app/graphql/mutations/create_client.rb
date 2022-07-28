module Mutations
  class CreateClient < BaseMutation
    argument :input, Types::HmisSchema::ClientInput, required: true

    type Types::HmisSchema::Client

    def resolve(input:)
      Hmis::Hud::Client.new(**input.to_params)
    end
  end
end
