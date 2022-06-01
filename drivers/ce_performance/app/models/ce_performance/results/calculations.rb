###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance::Results::Calculations
  extend ActiveSupport::Concern
  included do
    def self.average(values)
      return 0 unless values&.count&.positive?

      values.compact.sum.to_f / values.count
    end

    def self.median(values)
      return 0 unless values.any?

      values = values.map(&:to_f)
      mid = values.size / 2
      sorted = values.sort
      return sorted[mid] if values.length.odd?

      (sorted[mid] + sorted[mid - 1]) / 2
    end
  end
end
