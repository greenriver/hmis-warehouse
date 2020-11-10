###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module ProjectPerformance
    extend ActiveSupport::Concern
    included do
      def adjusted_utilization
        utilizations = [utilization_jan, utilization_apr, utilization_jul, utilization_oct].compact
        return nil if utilizations.empty?

        (utilizations.sum / utilizations.count.to_f).round
      end

      def utilization_percentage
        return nil unless [adjusted_utilization, utilization_proposed].all?

        ((adjusted_utilization / utilization_proposed.to_f) * 100).round
      end

      def utilization_score
        score(utilization_percentage, 90..150, 80..89)
      end

      def chronic_service_percentage
        return nil unless [chronic_households_served, total_households_served].all?

        ((chronic_households_served / total_households_served.to_f) * 100).round
      end

      def chronic_service_score
        score(chronic_service_percentage, 75..100, 65..74) if project.psh?
      end

      def unsuccessful_exits
        return nil unless [total_persons_exited, total_persons_with_positive_exit, excluded_exits].all?

        total_persons_exited - total_persons_with_positive_exit - excluded_exits
      end

      def exit_to_ph_percentage
        return nil unless [total_persons_served, unsuccessful_exits, excluded_exits].all?

        (((total_persons_served - unsuccessful_exits - excluded_exits) / (total_persons_served - excluded_exits).to_f) * 100).round
      end

      def exit_to_ph_score
        if project.psh?
          score(exit_to_ph_percentage, 98..100, 90..97)
        elsif project.rrh?
          score(exit_to_ph_percentage, 95..100, 90..94)
        end
      end

      def leavers_los_score
        score(average_los_leavers, 3..18, 19..24) if project.rrh?
      end

      def increased_employment_income_score
        if project.psh?
          score(percent_increased_employment_income_at_exit, 15..Float::INFINITY, 9..14)
        elsif project.rrh?
          score(percent_increased_employment_income_at_exit, 56..Float::INFINITY, 50..55)
        end
      end

      def increased_other_cash_income_score
        if project.psh?
          score(percent_increased_other_cash_income_at_exit, 61..Float::INFINITY, 55..60)
        elsif project.rrh?
          score(percent_increased_other_cash_income_at_exit, 21..Float::INFINITY, 15..20)
        end
      end

      def returns_to_homelessness_score
        score(percent_returns_to_homelessness, 0..5, 6..15)
      end
    end
  end
end
