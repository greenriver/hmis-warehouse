###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module BostonProjectScorecard
  module PolicyAlignment
    extend ActiveSupport::Concern
    included do
      # NOTE: all comparisons should be done against a rounded value
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

      def subpopulations_served_options
        {
          'Serving chronically homeless households' => 'Serving chronically homeless households',
          'Serving homeless youth' => 'Serving homeless youth',
          'Serving veterans' => 'Serving veterans',
          'Serving people fleeing domestic violence' => 'Serving people fleeing domestic violence',
          'Serving families with children' => 'Serving families with children',
        }
      end

      def subpopulations_served_value
        return if subpopulations_served.nil?

        subpopulations_served.reject(&:blank?)
      end

      def subpopulations_served_score
        return if subpopulations_served_value.nil?

        # 6 points, divided by number of options, round to one decimal place
        (subpopulations_served_value.length * (6 / subpopulations_served_options.length.to_f)).round(1)
      end

      def practices_housing_first_score
        return if practices_housing_first.nil?
        return 6 if practices_housing_first?

        0
      end

      def vulnerable_subpopulations_served_options
        {
          'Vulnerability to victimization (history of DV)' => 'Vulnerability to victimization (history of DV)',
          'Criminal histories' => 'Criminal histories',
          'Current or past substance abuse' => 'Current or past substance abuse',
          'Very little or no income at entry' => 'Very little or no income at entry',
          'Chronic homelessness' => 'Chronic homelessness',
          'Only project of its kind in the CoC, serving a special homeless population/sub-population' => 'Only project of its kind in the CoC, serving a special homeless population/sub-population',
        }
      end

      def vulnerable_subpopulations_served_value
        return if vulnerable_subpopulations_served.nil?

        vulnerable_subpopulations_served.reject(&:blank?)
      end

      def vulnerable_subpopulations_served_score
        return if vulnerable_subpopulations_served_value.nil?

        # 6 points, divided by number of options, round to 1 decimal place
        (vulnerable_subpopulations_served_value.length * (6 / vulnerable_subpopulations_served_options.length.to_f)).round(1)
      end

      def substance_use_treatment_service_options
        {
          'Required engagement in substance abuse treatment services as a condition of participation in the project' => 'Required engagement in substance abuse treatment services as a condition of participation in the project',
          'Onsite substance use treatment' => 'Onsite substance use treatment',
          'Sober housing in accordance with 24 CFR 578.93(b)(5)' => 'Sober housing in accordance with 24 CFR 578.93(b)(5)',
        }
      end

      def substance_use_treatment_service_value
        return if substance_use_treatment_service.nil?

        substance_use_treatment_service.reject(&:blank?)
      end

      def substance_use_treatment_service_score
        return if substance_use_treatment_service_value.nil?

        # 6 points, divided by number of options, round to 1 decimal place
        (substance_use_treatment_service_value.length * (6 / substance_use_treatment_service_options.length.to_f)).round(1)
      end

      def supportive_services_score
        return 0 unless supportive_services?

        10
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
