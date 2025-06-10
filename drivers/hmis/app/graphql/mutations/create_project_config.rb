###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

      class_name = input.config_type.constantize
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
