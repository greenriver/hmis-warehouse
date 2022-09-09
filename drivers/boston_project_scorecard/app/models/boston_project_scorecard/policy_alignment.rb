###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module PolicyAlignment
    extend ActiveSupport::Concern
    included do
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

        # 6 points, divided by nuumber of options, round to one decimal place
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

        # 6 points, divided by nuumber of options, round to 1 decimal place
        (vulnerable_subpopulations_served_value.length * (6 / vulnerable_subpopulations_served_options.length.to_f)).round(1)
      end
    end
  end
end
