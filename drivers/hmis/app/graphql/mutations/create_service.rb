module Mutations
  class CreateService < BaseMutation
    argument :input, Types::HmisSchema::ServiceInput, required: true

    field :service, Types::HmisSchema::Service, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      user = hmis_user

      service = Hmis::Hud::Service.new(
        services_id: Hmis::Hud::Service.generate_services_id,
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        date_updated: DateTime.current,
        date_created: DateTime.current,
        **input.to_params,
      )

      if service.valid?
        service.save!
      else
        errors = service.errors
        service = nil
      end

      {
        service: service,
        errors: errors,
      }
    end
  end
end
