###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteProjectConfig < CleanBaseMutation
    argument :id, ID, required: true

    field :project_config, Types::HmisSchema::ProjectConfig, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = Hmis::ProjectConfig.find(id)
      raise 'Access denied' unless allowed?(permissions: [:can_configure_data_collection])

      record.destroy!

      {
        project_config: record,
        errors: [],
      }
    end
  end
end
