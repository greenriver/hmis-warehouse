module Mutations
  class DeleteService < BaseMutation
    argument :id, ID, required: true

    field :service, Types::HmisSchema::Service, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:)
      errors = []
      service = Hmis::Hud::Service.find_by(id: id)

      if service.present?
        service.destroy
      else
        errors << InputValidationError.new("No service found with ID '#{id}'", attribute: 'id')
      end

      {
        service: service,
        errors: errors,
      }
    end
  end
end
