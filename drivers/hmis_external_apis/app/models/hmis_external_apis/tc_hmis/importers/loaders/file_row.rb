###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

    def field_value_by_id(id, required: false)
      raise "row is nil. looking for field '#{field}' #{caller.inspect}" if row.nil?

      value = row[:by_id][id]
      return value if value
      raise "id '#{id}' is missing from row: #{context} caller: #{caller.inspect}" if required
    end

    def field_value(label, required: false)
      raise "row is nil. looking for field '#{field}' #{caller.inspect}" if row.nil?

      value = row[label.to_s]
      return value if value
      raise "field '#{label}' is missing from row: #{context} caller: #{caller.inspect}" if required
    end
  end
end
