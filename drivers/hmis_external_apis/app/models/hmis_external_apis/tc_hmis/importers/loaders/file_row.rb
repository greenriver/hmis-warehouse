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

    def field_value(label, required: false, id: nil)
      raise "row is nil. looking for field '#{field}' #{caller.inspect}" if row.nil?

      by_id = row[label]
      value = nil
      if id.nil?
        raise "field '#{label}' is has multiple values. You must specify an id" if by_id.many?

        value = by_id.values.first
      else
        value = by_id[id]
      end

      return value if value
      raise "field '#{label}' is missing from row: #{context} caller: #{caller.inspect}" if required
    end
  end
end
