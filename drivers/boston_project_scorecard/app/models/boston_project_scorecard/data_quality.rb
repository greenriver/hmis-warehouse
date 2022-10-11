###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module DataQuality
    extend ActiveSupport::Concern
    included do
      def pii_error_rate_value
        percentage_string(pii_error_rate)
      end

      def ude_error_rate_value
        percentage_string(ude_error_rate)
      end

      def income_and_housing_error_rate_value
        percentage_string(income_and_housing_error_rate)
      end

      def dq_score(value)
        return 5 if value <= 20

        0
      end

      def pii_error_rate_score
        dq_score(pii_error_rate)
      end

      def ude_error_rate_score
        dq_score(ude_error_rate)
      end

      def income_and_housing_error_rate_score
        dq_score(income_and_housing_error_rate)
      end
    end
  end
end
