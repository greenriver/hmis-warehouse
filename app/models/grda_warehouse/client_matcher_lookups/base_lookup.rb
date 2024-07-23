###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
