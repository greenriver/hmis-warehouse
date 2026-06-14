###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Custom error class for IDP service operations.
  class ServiceError < StandardError
    attr_reader :idp_name, :operation

    def initialize(message, idp_name: nil, operation: nil)
      super(message)
      @idp_name = idp_name
      @operation = operation
    end
  end
end
