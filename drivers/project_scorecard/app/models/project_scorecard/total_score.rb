###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ProjectScorecard
  module TotalScore
    extend ActiveSupport::Concern
    included do
      def project_performance_score
        [
          utilization_score,
          exit_to_ph_score,
          leavers_los_score,
          increased_employment_income_score,
          increased_other_cash_income_score,
          returns_to_homelessness_score,
        ].compact.sum
      end

      def project_performance_max
        base = key_project.rrh? ? 50 : 45
        # SPM data (returns to homelessness) is an optional supplemental report that is
        # commonly absent even for otherwise-complete scorecards, so we lower the denominator
        # when it is missing. APR-sourced fields (LOS, exit to PH, etc.) are loaded as a
        # batch; if any are missing the report is not yet complete and the denominator is moot.
        base -= 15 if returns_to_homelessness_score.blank?
        base
      end

      def project_performance_percentage
        (((project_performance_score / project_performance_max.to_f) * 0.5) * 100).round
      end

      def data_quality_score
        [
          pii_errors_score,
          ude_errors_score,
          income_and_housing_errors_score,
        ].compact.sum
      end

      def data_quality_max
        30
      end

      def data_quality_percentage
        (((data_quality_score / data_quality_max.to_f) * 0.2) * 100).round
      end

      def ce_score
        [
          lease_up_score,
          accepted_referrals_score,
        ].compact.sum
      end

      def ce_max
        20
      end

      def ce_percentage
        (((ce_score / ce_max.to_f) * 0.2) * 100).round
      end

      def m_and_f_score
        [
          spend_down_score,
          cost_efficiency_score,
          recaptured_score,
          supportive_services_score,
          pit_participation_score,
          meetings_attended_score,
        ].compact.sum
      end

      def m_and_f_max
        return 40 if expansion_year

        50
      end

      def m_and_f_percentage
        (((m_and_f_score / m_and_f_max.to_f) * 0.1) * 100).round
      end
    end
  end
end
