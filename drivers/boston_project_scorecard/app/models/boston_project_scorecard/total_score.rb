###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module TotalScore
    extend ActiveSupport::Concern
    included do
      def project_performance_score
        [
          rrh_exits_to_ph_score,
          psh_stayers_or_to_ph_score,
          increased_stayer_employment_income_score,
          increased_stayer_other_income_score,
          increased_leaver_employment_income_score,
          increased_leaver_other_income_score,
          days_to_lease_up_score,
        ].compact.sum
      end

      def project_performance_available
        max = 48
        max -= 24 unless rrh? || psh?

        max
      end

      def project_performance_weight
        38
      end

      def project_performance_weighted_score
        ((project_performance_score / project_performance_available.to_f) * project_performance_weight).round(2)
      end

      def data_quality_score
        [
          pii_error_rate_score,
          ude_error_rate_score,
          income_and_housing_error_rate_score,
        ].compact.sum
      end

      def data_quality_available
        15
      end

      def data_quality_weight
        12
      end

      def data_quality_weighted_score
        ((data_quality_score / data_quality_available.to_f) * data_quality_weight).round(2)
      end

      def financial_performance_score
        [
          project_type_score,
          invoicing_score,
          efficiency_score,
          required_match_score,
          returned_funds_score,
          utilization_rate_score,
        ].compact.sum
      end

      def financial_performance_available
        36
      end

      def financial_performance_weight
        29
      end

      def financial_performance_weighted_score
        ((financial_performance_score / financial_performance_available.to_f) * financial_performance_weight).round(2)
      end

      def policy_alignment_score
        [
          subpopulations_served_score,
          practices_housing_first_score,
          vulnerable_subpopulations_served_score,
        ].compact.sum + racial_equity_score
      end

      def policy_alignment_available
        18 + racial_equity_available
      end

      def policy_alignment_weight
        21
      end

      def policy_alignment_weighted_score
        ((policy_alignment_score / policy_alignment_available.to_f) * policy_alignment_weight).round(2)
      end

      def racial_equity_score
        [
          barrier_id_process_score,
          plan_to_address_barriers_score,
        ].compact.sum
      end

      def racial_equity_available
        8
      end

      def racial_equity_weight
        # Not used, as currently rolled into Policy Alignment
        0
      end

      def racial_equity_weighted_score
        # Not used, as currently rolled into Policy Alignment
        ((racial_equity_score / racial_equity_available.to_f) * racial_equity_weight).round(2)
      end

      def total_score_score
        [
          project_performance_score,
          data_quality_score,
          financial_performance_score,
          policy_alignment_score,
          # racial_equity_score, # Rolled into Policy Alignment
        ].compact.sum
      end

      def total_score_available
        [
          project_performance_available,
          data_quality_available,
          financial_performance_available,
          policy_alignment_available,
          # racial_equity_available, # Rolled into Policy Alignment
        ].compact.sum
      end

      def total_score_weight
        [
          project_performance_weight,
          data_quality_weight,
          financial_performance_weight,
          policy_alignment_weight,
          # racial_equity_weight, # Rolled into Policy Alignment
        ].compact.sum
      end

      def total_score_weighted_score
        [
          project_performance_weighted_score,
          data_quality_weighted_score,
          financial_performance_weighted_score,
          policy_alignment_weighted_score,
          # racial_equity_weighted_score, # Rolled into Policy Alignment
        ].compact.sum
      end
    end
  end
end
