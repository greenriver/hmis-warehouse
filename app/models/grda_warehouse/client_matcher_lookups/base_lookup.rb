###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::ClientMatcherLookups
  class BaseLookup
    attr_accessor :values
    def initialize
      self.values = {}
    end

    # def add(client_stub)
    # end
  end
end
