###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  class ServiceError < StandardError
    attr_reader :idp_name, :operation

    # transient: false when the IdP answered fine and will keep giving the same answer until someone
    # changes a setting there. Retries and the sync job's circuit breaker only make sense for a
    # connector that might answer differently in a moment, so neither applies to those.
    def initialize(message, idp_name: nil, operation: nil, transient: true)
      super(message)
      @idp_name = idp_name
      @operation = operation
      @transient = transient
    end

    def transient?
      @transient
    end
  end
end
