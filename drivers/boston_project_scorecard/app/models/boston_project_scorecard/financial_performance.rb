###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

      # Report is only functional for PSH, RRH and Joint TH-PH projects
      def project_type_score
        return 6 if project_type.in?([3, 9, 10]) # PSH, PH - housing only, PH - with services
        return 3 if project_type.in?([13]) # RRH

        0
      end

      def invoicing_timeliness_options
        {
          'Invoices regularly submitted on time': 3,
          'Invoices submitted usually on time': 2,
          'Invoices submitted quarterly or less frequently than monthly': 1,
        }
      end

      def invoicing_timeliness_score
        invoicing_timeliness
      end

      def invoicing_accuracy_options
        {
          'Invoices regularly complete and accurate': 3,
          'Invoices occasionally contain a few errors': 2,
          'Invoices frequently contain errors that require correction': 1,
        }
      end

      def invoicing_accuracy_score
        invoicing_accuracy
      end

      def cost_efficiency_value
        return unless amount_agency_spent.present? && actual_households_served&.positive?

        (amount_agency_spent / actual_households_served.to_f).round(2)
      end

      def efficiency_score
        return unless cost_efficiency_value.present?

        return 6 if cost_efficiency_value <= 4000

        0
      end

      def required_match_score
        return unless required_match_percent_met.present?
        return 6 if required_match_percent_met?

        0
      end

      def returned_funds_percent
        return unless returned_funds.present? && contracted_budget.present?

        percentage(returned_funds / contracted_budget.to_f)
      end

      def returned_funds_value
        return unless returned_funds_percent.present?

        percentage_string(returned_funds_percent)
      end

      def returned_funds_score
        return unless returned_funds_percent.present?
        return 6 if returned_funds_percent <= 5
        return 3 if returned_funds_percent <= 10

        0
      end
    end
  end
end
