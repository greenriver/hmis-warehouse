###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module ProjectPerformance
    extend ActiveSupport::Concern
    included do
      # NOTE: all comparisons shoud be done against a rounded value
      def no_concern_options
        {
          'Providers with 90% or more "no concern"': 3,
          'Providers with 85% to 89% "no concern"': 2,
          'Providers with 80% to 84% "no concern"': 1,
          'Providers with 79% or less "no concern"': 0,
          'Not Applicable': -1,
        }
      end

      def materials_concern_options
        {
          'All materials were submitted on time': 3,
          'Materials were submitted but deadline was missed': 1,
          'Materials were not submitted': 0,
          'Not Applicable': -1,
        }
      end

      def rrh?
        project_type == 13
      end

      def psh?
        project_type.in?([3, 9, 10])
      end

      def rrh_exits_to_ph_value
        percentage_string(rrh_exits_to_ph) if rrh?
      end

      def psh_stayers_or_to_ph_value
        percentage_string(psh_stayers_or_to_ph) if psh?
      end

      def increased_employment_income_value
        percentage_string(increased_employment_income)
      end

      def increased_other_income_value
        percentage_string(increased_other_income)
      end

      def days_to_lease_up_value
        days_to_lease_up
      end

      def days_to_lease_up_change
        return unless days_to_lease_up_comparison&.positive?

        ((days_to_lease_up - days_to_lease_up_comparison.to_f) / days_to_lease_up_comparison) * 100
      end

      def rrh_exits_to_ph_score
        return unless rrh?

        return 12 if rrh_exits_to_ph.round >= 75
        return 6 if rrh_exits_to_ph.round >= 55
        return 4 if rrh_exits_to_ph.round >= 25

        0
      end

      def psh_stayers_or_to_ph_score
        return unless psh?

        return 12 if psh_stayers_or_to_ph.round >= 75
        return 6 if psh_stayers_or_to_ph.round >= 55
        return 4 if psh_stayers_or_to_ph.round >= 25

        0
      end

      def increased_employment_income_score
        return 0 unless increased_employment_income

        return 12 if increased_employment_income.round >= 20
        return 6 if increased_employment_income.round >= 15
        return 4 if increased_employment_income.round >= 7

        0
      end

      def increased_other_income_score
        return 0 unless increased_other_income

        return 12 if increased_other_income.round >= 50
        return 6 if increased_other_income.round >= 37
        return 4 if increased_other_income.round >= 17

        0
      end

      # NOTE: if days_to_lease_up_comparison is 0 or blank, points are only given based on
      # overall days within the current year
      def days_to_lease_up_score
        return 12 if days_to_lease_up < 90
        return 12 if days_to_lease_up_change.present? && days_to_lease_up_change.round < -5
        return 6 if days_to_lease_up_change.present? && days_to_lease_up_change.round < -1

        0
      end

      def utilization_rate_percent
        return unless average_utilization_rate.present? && actual_households_served.present?

        percentage(average_utilization_rate / actual_households_served.to_f)
      end

      def utilization_rate_value
        return unless utilization_rate_percent.present?

        percentage_string(utilization_rate_percent)
      end

      def utilization_rate_score
        return unless utilization_rate_percent.present?
        return 6 if utilization_rate_percent.round >= 85
        return 3 if utilization_rate_percent.round >= 75

        0
      end

      # No-concern and materials-concern are interrelated, and only one can be chosen.
      # Preference no-concern since it's first on the page
      def no_concern_score
        return nil if no_concern&.negative?

        no_concern
      end

      def materials_concern_score
        return nil if materials_concern&.negative? || no_concern_score.present? && no_concern > -1

        materials_concern
      end
    end
  end
end
