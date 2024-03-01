###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateProjectConfig < CleanBaseMutation
    argument :input, Types::HmisSchema::ProjectConfigInput, required: true

    field :project_config, Types::HmisSchema::ProjectConfig, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      errors = HmisErrors::Errors.new
      errors.add :config_type, :required if input.config_type.blank?
      return { errors: errors } if errors.any?

      class_name = case input.config_type
      when 'AUTO_ENTER'
        Hmis::ProjectAutoEnterConfig
      when 'AUTO_EXIT'
        Hmis::AutoExitConfig
      else raise "Unsupported type: #{input.config_type}"
      end

      default_create_record(
        class_name,
        field_name: :project_config,
        input: input,
        permissions: [:can_configure_data_collection],
        exclude_default_fields: true,
      )
    end
  end
end