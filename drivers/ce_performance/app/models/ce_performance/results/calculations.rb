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

    def self.display_result?
      true
    end

    def self.ce_apr_question
      nil
    end

    def percentage?
      false
    end

    def max_100?
      false
    end

    def goal_line
      self.class.goal
    end

    def chart_slug
      self.class.name.split('::').last.underscore.dasherize
    end

    def passed?(_comparison)
      return true unless self.class.goal.present?

      value.present? && value <= self.class.goal
    end

    def titles_for_bar_tooltip(report)
      [report.filter.date_range_words, report.filter.comparison_range_words]
    end

    def direction(comparison)
      return :none if value == comparison.value
      return :up if (value.presence || 0) > (comparison.value.presence || 0)

      :down
    end

    def percent_change_over_year(comparison)
      return 0 unless value.present?
      return 100 if comparison.value.blank? || comparison.value.zero?

      self.class.percent_of(value - comparison.value, comparison.value)
    end

    def change_over_year(comparison)
      return 0 unless value.present?

      value - comparison.value
    end

    def self.percent_of(numerator, denominator)
      return 0 unless denominator.positive?

      ((numerator / denominator.to_f) * 100).round
    end
  end
end
