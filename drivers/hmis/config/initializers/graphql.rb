###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GraphQLTypesISO8601DateDateDeprecation
  TodoOrDie('Remove deprecated date/time.to_s', by: '2024-07-01')
  # Temporary fix to avoid generating tons of deprecation warnings related Date#to_s
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
