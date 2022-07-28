module Mutations
  class CreateClient < BaseMutation
    argument :input, Types::HmisSchema::ClientInput, required: true

    type Types::HmisSchema::Client

    # def resolve(input:)
    #   # params = input.to_params
    #   Hmis::Hud::Client.first
    # end
  end
end
