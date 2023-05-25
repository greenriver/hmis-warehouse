###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module ProjectPerformance
    extend ActiveSupport::Concern
    included do
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

      def rrh_exits_to_ph_score
        return unless rrh?

        return 12 if rrh_exits_to_ph >= 75
        return 6 if rrh_exits_to_ph >= 55
        return 4 if rrh_exits_to_ph >= 25

        0
      end

      def psh_stayers_or_to_ph_score
        return unless psh?

        return 12 if psh_stayers_or_to_ph >= 75
        return 6 if psh_stayers_or_to_ph >= 55
        return 4 if psh_stayers_or_to_ph >= 25

        0
      end

      def performance_score(value)
        return 0 unless value

        return 12 if value >= 75
        return 6 if value >= 55
        return 4 if value >= 25

        0
      end

      def increased_employment_income_score
        performance_score(increased_employment_income)
      end

      def increased_other_income_score
        performance_score(increased_other_income)
      end

      def days_to_lease_up_score
        return 0 if days_to_lease_up < 1
        return 12 if days_to_lease_up <= 30
        return 6 if days_to_lease_up <= 60
        return 4 if days_to_lease_up <= 180

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
        return 6 if utilization_rate_percent >= 85
        return 3 if utilization_rate_percent >= 75

        0
      end
    end
  end
end
