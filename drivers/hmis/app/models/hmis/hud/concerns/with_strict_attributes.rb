###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Concerns::WithStrictAttributes
  extend ActiveSupport::Concern

  included do
    raise "#{self} cannot include Hmis::Hud::Concerns::WithStrictAttributes because the table #{table_name} does not exist. Try moving `self.table_name` assignment to the top of the file." unless table_exists?

    columns.each do |column|
      case column.type
      when :integer
        attribute column.name, Hmis::StrictInteger.new
      when :decimal
        attribute column.name, Hmis::StrictDecimal.new
      end
    end
  end
end
