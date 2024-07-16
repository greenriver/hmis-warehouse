###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientMatcherLookups
  class DOBLookup < BaseLookup
    def get_ids(dob:)
      return [] unless dob

      @values[dob]&.uniq || []
    end

    def add(client)
      return unless client.dob

      @values[client.dob] ||= []
      @values[client.dob].push(client.id)
    end
  end
end
