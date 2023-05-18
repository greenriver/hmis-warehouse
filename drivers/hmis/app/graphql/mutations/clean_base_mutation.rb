###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# avoid pollution from relay
module Mutations
  class CleanBaseMutation < GraphQL::Schema::Mutation
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def current_user
      context[:current_user]
    end

    def hmis_user
      Hmis::Hud::User.from_user(current_user)
    end
  end
end
