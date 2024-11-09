###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'
module GrdaWarehouse::Tasks::ScrubPii
  class IdentifierStrategy < BaseStrategy
    def client_attrs(client)
      result = [
        :FirstName,
        :MiddleName,
        :LastName,
      ].to_h do |field|
        [field, field_value(client, field)]
      end
      result[:NameDataQuality] = 2
      super(client).merge(result)
    end

    protected

    def field_value(record, field)
      "#{field}#{record.id}"
    end
  end
end
