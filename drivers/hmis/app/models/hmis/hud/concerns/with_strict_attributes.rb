###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Concerns::WithStrictAttributes
  # Add validations on ALL numerical columns (int/decimal) on HUD models,
  # to prevent the default Rails/Postgres behavior of silently casting non-numeric strings to 0.

  extend ActiveSupport::Concern

  included do
    raise "#{self} cannot include Hmis::Hud::Concerns::WithStrictAttributes because the table #{table_name} does not exist. Try moving `self.table_name` assignment to the top of the class." unless table_exists?

    columns.each do |column|
      case column.type
      when :integer, :bigint
        validates column.name, hud_numericality: { integer: true }
      when :decimal, :float
        validates column.name, hud_numericality: { integer: false }
      end
    end
  end
end
