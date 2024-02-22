###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateAutoExitConfig < CleanBaseMutation
    argument :input, Types::HmisSchema::AutoExitConfigInput, required: true
    argument :id, ID, required: true

    field :auto_exit_config, Types::HmisSchema::AutoExitConfig, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, input:)
      record = Hmis::ProjectAutoExitConfig.find(id)
      raise 'Access denied' unless allowed?(permissions: [:can_configure_data_collection])

      record.assign_attributes(**input.to_params)

      if record.valid?
        record.save!
      else
        errors = record.errors
        record = nil
      end

      {
        record: record,
        errors: errors,
      }
    end
  end
end
