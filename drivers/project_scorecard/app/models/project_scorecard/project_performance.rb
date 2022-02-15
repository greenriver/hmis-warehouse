###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        return nil if utilization_proposed.zero?

        ((adjusted_utilization / utilization_proposed.to_f) * 100).round
      end

      def utilization_score
        score(utilization_percentage, 90..Float::INFINITY, 80..89)
      end

      def chronic_service_percentage
        return nil unless [chronic_households_served, total_households_served].all?
        return 0 unless total_households_served.positive?

        ((chronic_households_served / total_households_served.to_f) * 100).round
      end

      def chronic_service_score
        score(chronic_service_percentage, 75..100, 65..74) if key_project.psh? || key_project.sh?
      end

      def unsuccessful_exits
        return nil unless [total_persons_exited, total_persons_with_positive_exit, excluded_exits].all?

        total_persons_exited - total_persons_with_positive_exit - excluded_exits
      end

      def exit_to_ph_percentage
        return nil unless [total_persons_served, unsuccessful_exits, excluded_exits].all?
        return 0 unless (total_persons_served - excluded_exits).positive?

        (((total_persons_served - unsuccessful_exits - excluded_exits) / (total_persons_served - excluded_exits).to_f) * 100).round
      end

      def exit_to_ph_score
        if key_project.psh? || key_project.sh?
          score(exit_to_ph_percentage, 98..100, 90..97)
        elsif key_project.rrh?
          score(exit_to_ph_percentage, 95..100, 90..94)
        else
          score(exit_to_ph_percentage, 95..100, 90..94)
        end
      end

      def los_months
        average_los_leavers / 30
      end

      def leavers_los_score
        score(los_months, 3..18, 19..24) if key_project.rrh?
      end

      def increased_employment_income_score
        if key_project.psh? || key_project.sh?
          score(percent_increased_employment_income_at_exit, 15..Float::INFINITY, 9..14)
        elsif key_project.rrh?
          score(percent_increased_employment_income_at_exit, 56..Float::INFINITY, 50..55)
        end
      end

      def increased_other_cash_income_score
        if key_project.psh? || key_project.sh?
          score(percent_increased_other_cash_income_at_exit, 61..Float::INFINITY, 55..60)
        elsif key_project.rrh?
          score(percent_increased_other_cash_income_at_exit, 21..Float::INFINITY, 15..20)
        end
      end

      def returns_to_homelessness_score
        score(percent_returns_to_homelessness, 0..5, 6..15)
      end
    end
  end
end
