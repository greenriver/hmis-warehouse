###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
      access_denied! unless policy_for(Hmis::ProjectConfig, policy_type: :project_config).can_manage?
      record = Hmis::ProjectConfig.find(id)
      record.destroy!

      {
        project_config: record,
        errors: [],
      }
    end
  end
end
