###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class UpdateProjectConfig < CleanBaseMutation
    argument :input, Types::HmisSchema::ProjectConfigInput, required: true
    argument :id, ID, required: true

    field :project_config, Types::HmisSchema::ProjectConfig, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, input:)
      record = Hmis::ProjectConfig.find(id)
      access_denied! unless policy_for(record, policy_type: :project_config).can_update?

      errors = HmisErrors::Errors.new
      # Config type cannot be changed once set. Frontend prevents it, but return a validation
      # instead of raising for backwards compatibility.
      if input.config_type.present? && input.config_type != record.config_type
        errors.add(:config_type, :invalid, message: 'cannot be changed once set')
        return { project_config: nil, errors: errors.errors }
      end

      record.assign_attributes(**input.to_params)

      if record.valid?
        record.save!
      else
        errors.add_ar_errors(record.errors.errors)
        record = nil
      end

      {
        project_config: record,
        errors: errors.errors,
      }
    end
  end
end
