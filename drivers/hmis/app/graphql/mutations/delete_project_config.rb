###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteProjectConfig < CleanBaseMutation
    argument :id, ID, required: true

    field :project_config, Types::HmisSchema::ProjectConfig, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = Hmis::ProjectConfig.find(id)
      access_denied! unless policy_for(record, policy_type: :project_config).can_destroy?
      record.destroy!

      {
        project_config: record,
        errors: [],
      }
    end
  end
end
