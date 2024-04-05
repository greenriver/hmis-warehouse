###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###


module GraphQLTypesISO8601DateDateDeprecation
  # This will get fixed in graphql eventually
  # Fix "Using a :default format for Date#to_s is deprecated"
  def self.coerce_result(value, _ctx)
    case value
    when Date, DateTime
      super(value.to_fs)
    else
      super(value)
    end
  end
end

GraphQL::Types::ISO8601Date.prepend(GraphQLTypesISO8601DateDateDeprecation)
