###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Resolvers
  class ValidationErrors < Resolvers::Base
    type [Types::HmisSchema::ValidationError], null: false

    # Resolve HmisErrors and AR errors as a flattened list of HmisErrors
    def resolve
      return [] unless object[:errors].present?

      errors = object[:errors]
      errors = errors.errors if errors.instance_of?(::HmisErrors::Errors)

      errors.map do |error|
        if error.instance_of?(::HmisErrors::Error)
          error
        elsif error.instance_of?(ActiveModel::Error)
          ::HmisErrors::Error.from_ar_error(error)
        elsif error.instance_of?(ActiveModel::NestedError)
          ::HmisErrors::Error.from_ar_error(error)
        else
          raise "Unrecognized error type: #{error.class}"
        end
      end
    end
  end
end
