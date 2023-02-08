module Mutations
  class CreateFunder < BaseMutation
    argument :input, Types::HmisSchema::FunderInput, required: true

    field :funder, Types::HmisSchema::Funder, null: true

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
