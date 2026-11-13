###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  class ServiceError < StandardError
    attr_reader :idp_name, :operation

    # transient: false when the IdP answered fine and keeps giving the same answer until an operator
    # changes something there. Neither a retry nor the sync job's cooldown helps with those.
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
