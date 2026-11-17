###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  DisplayRow = Struct.new(:label, :header, :level, :format, :value, :parts, keyword_init: true) do
    def display_value
      case format.to_s
      when 'count' then ActiveSupport::NumberHelper.number_to_delimited(value.to_i)
      when 'percent' then "#{(value.to_f * 100).round(2)}%"
      when 'decimal' then value.to_f.round(2).to_s
      end
    end
  end
end
