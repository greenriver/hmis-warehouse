###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module BostonProjectScorecard
  module TotalScore
    extend ActiveSupport::Concern
    included do
      def project_performance_score
        [
          rrh_exits_to_ph_score, # max 12 (incompatible with psh_stayers_or_to_ph_score)
          returns_to_homelessness_score, # max 12
          psh_stayers_or_to_ph_score, # max 12 (incompatible with rrh_exits_to_ph_score)
          increased_employment_income_score, # max 12
          increased_other_income_score, # max 12
          days_to_lease_up_score, # max 12
          utilization_rate_score, # max 6
          no_concern_score, # max 3
        ].compact.sum
      end

      def project_performance_available
        max = 69
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
          invoicing_timeliness_score,
          invoicing_accuracy_score,
          efficiency_score,
          required_match_score,
          supportive_services_score,
          returned_funds_score,
        ].compact.sum
      end

      def financial_performance_available
        24
      end

      def financial_performance_weight
        29
      end

      def financial_performance_weighted_score
        ((financial_performance_score / financial_performance_available.to_f) * financial_performance_weight).round(2)
      end

      def policy_alignment_score
        [
          project_type_score,
          subpopulations_served_score,
          substance_use_treatment_service_score,
        ].compact.sum
      end

      def policy_alignment_available
        28
      end

      def policy_alignment_weight
        21
      end

      def policy_alignment_weighted_score
        ((policy_alignment_score / policy_alignment_available.to_f) * policy_alignment_weight).round(2)
      end

      def total_score_score
        [
          project_performance_score,
          data_quality_score,
          financial_performance_score,
          policy_alignment_score,
        ].compact.sum
      end

      def total_score_available
        [
          project_performance_available,
          data_quality_available,
          financial_performance_available,
          policy_alignment_available,
        ].compact.sum
      end

      def total_score_weight
        [
          project_performance_weight,
          data_quality_weight,
          financial_performance_weight,
          policy_alignment_weight,
        ].compact.sum
      end

      def total_score_weighted_score
        [
          project_performance_weighted_score,
          data_quality_weighted_score,
          financial_performance_weighted_score,
          policy_alignment_weighted_score,
        ].compact.sum.round(2)
      end
    end
  end
end
