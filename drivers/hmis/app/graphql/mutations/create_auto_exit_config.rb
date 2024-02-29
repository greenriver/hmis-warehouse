###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateAutoExitConfig < CleanBaseMutation
    argument :input, Types::HmisSchema::AutoExitConfigInput, required: true

    field :auto_exit_config, Types::HmisSchema::AutoExitConfig, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      default_create_record(
        Hmis::ProjectAutoExitConfig,
        field_name: :auto_exit_config,
        input: input,
        permissions: [:can_configure_data_collection],
        exclude_default_fields: true,
      )
    end
  end
end
