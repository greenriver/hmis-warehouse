module Mutations
  class CreateFunder < BaseMutation
    argument :input, Types::HmisSchema::FunderInput, required: true

    field :funder, Types::HmisSchema::Funder, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      default_create_record(
        Hmis::Hud::Funder,
        field_name: :funder,
        id_field_name: :funder_id,
        input: input,
      )
    end
  end
end
