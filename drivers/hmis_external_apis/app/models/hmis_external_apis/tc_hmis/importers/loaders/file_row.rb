###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'

module HmisExternalApis::TcHmis::Importers::Loaders
  class FileRow
    attr_accessor :row
    delegate :[], :to_h, to: :row
    def initialize(row)
      self.row = row
    end

    def context
      row.values_at(:filename, :row_number).compact.join(':')
    end

    def field_value(field, required: false)
      raise "row is nil. looking for field '#{field}' #{caller.inspect}" if row.nil?

      value = row[field]&.strip&.presence
      raise "field '#{field}' is missing from row: #{context} caller: #{caller.inspect}" if required && !value

      value
    end
  end
end
