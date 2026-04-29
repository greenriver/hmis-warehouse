###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteServiceType < CleanBaseMutation
    graphql_name 'DeleteServiceType'
    argument :id, ID, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:)
      service_type = Hmis::Hud::CustomServiceType.find(id)
      access_denied! unless policy_for(service_type, policy_type: :service_type).can_destroy?

      # Can't delete service type that already has services
      if service_type.custom_services.exists?
        errors = HmisErrors::Errors.new
        errors.add :base, :invalid, full_message: 'Cannot delete a service type that has services'
        return { errors: errors }
      end

      service_type.destroy!

      {
        service_type: service_type,
        errors: [],
      }
    end
  end
end
