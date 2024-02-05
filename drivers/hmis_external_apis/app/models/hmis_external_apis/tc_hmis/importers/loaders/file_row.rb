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

    def field_value(field, required: false, index: nil)
      raise "row is nil. looking for field '#{field}' #{caller.inspect}" if row.nil?

      values = row[field]
      if values.blank?
        raise "field '#{field}' is missing from row: #{context} caller: #{caller.inspect}" if required
        nil
      elsif index
        values[index]
      else
        raise "field '#{field}' is multi-valued. You must specify index" if values.many?

        values.first
      end
    end
  end
end
