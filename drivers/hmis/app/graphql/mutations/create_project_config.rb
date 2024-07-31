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
      access_denied! unless current_user.can_configure_data_collection?

      errors = HmisErrors::Errors.new
      errors.add :config_type, :required if input.config_type.blank?
      return { errors: errors } if errors.any?

      class_name = case input.config_type
      when 'AUTO_ENTER'
        Hmis::ProjectAutoEnterConfig
      when 'AUTO_EXIT'
        Hmis::ProjectAutoExitConfig
      when 'STAFF_ASSIGNMENT'
        Hmis::ProjectStaffAssignmentConfig
      else raise "Unsupported type: #{input.config_type}"
      end

      record = class_name.new(input.to_params)
      if record.valid?
        record.save!
      else
        errors = record.errors
        record = nil
      end

      {
        project_config: record,
        errors: errors,
      }
    end
  end
end
