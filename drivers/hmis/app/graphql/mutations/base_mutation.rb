###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include GraphqlMutationHelper
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    # can't use skip_activity_log due to load order?
    def activity_log_object_identity
      nil
    end
  end
end
