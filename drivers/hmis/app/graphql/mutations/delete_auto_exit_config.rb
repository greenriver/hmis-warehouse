###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteAutoExitConfig < CleanBaseMutation
    argument :id, ID, required: true

    field :auto_exit_config, Types::HmisSchema::AutoExitConfig, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = Hmis::AutoExitConfig.find(id)
      return { errors: [HmisErrors::Error.new(:auto_exit_config, :not_allowed)] } unless allowed?(permissions: [:can_configure_data_collection])

      record.destroy!

      {
        auto_exit_config: record,
        errors: [],
      }
    end
  end
end
