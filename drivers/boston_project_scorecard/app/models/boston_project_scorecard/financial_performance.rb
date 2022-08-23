###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module FinancialPerformance
    extend ActiveSupport::Concern
    included do
      def project_type_value
        case project_type
        when 3
          'PSH'
        when 9, 10
          'PH'
        when 13
          'RRH'
        else
          'Other'
        end
      end

      def project_type_score
        return 6 if project_type == 3 # PSH
        return unless project_type.in?(9, 10, 13)

        3
      end

      def invoicing_options
        {
          'Invoices regularly submitted on time': 6,
          'Usually on time, complete with few errors': 3,
          'Submitted quarterly/not monthly': 1,
        }
      end

      def invoicing_score
        invoicing
      end

      def cost_efficiency_value
        return unless actual_households_served&.positive?

        (application_budget / actual_households_served.to_f).round(2)
      end

      def staff_efficiency_value
        return unless actual_households_served&.positive?

        (proposal_ftes / actual_households_served.to_f).round(2)
      end

      def efficiency_score
        return unless cost_efficiency_value.present? && staff_efficiency_value.present?
        return 6 if psh? && cost_efficiency_value > 4000 && staff_efficiency_value >= 15 && staff_efficiency_value <= 20
        return 6 if rrh? && cost_efficiency_value > 4000 && staff_efficiency_value >= 20 && staff_efficiency_value <= 30

        0
      end

      def contracted_budget
        application_budget
      end

      def required_match_percent
        return unless contracted_budget.present?

        percentage(amount_agency_spent / contracted_budget.to_f)
      end

      def required_match_value
        return unless required_match_percent.present?

        percentage_string(required_match_percent)
      end

      def required_match_score
        return unless required_match_percent.present?
        return 6 if required_match_percent >= 25

        0
      end

      def returned_funds_budget
        application_budget
      end

      def returned_funds_percent
        return unless returned_funds_budget.present?

        percentage(returned_funds / returned_funds_budget.to_f)
      end

      def returned_funds_value
        return unless required_match_percent.present?

        percentage_string(returned_funds_percent)
      end

      def returned_funds_score
        return unless returned_funds_budget.present?
        return 6 if returned_funds_percent <= 10

        0
      end

      def utilization_rate_percent
        return unless proposed_households_served.present?

        percentage(average_utilization_rate / proposed_households_served.to_f)
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
