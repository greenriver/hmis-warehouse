###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module DataQuality
    extend ActiveSupport::Concern
    included do
      def pii_errors_score
        score(percent_pii_errors, 0..1, 2..5)
      end

      def ude_errors_score
        score(percent_ude_errors, 0..1, 2..5)
      end

      def income_and_housing_errors_score
        score(percent_income_and_housing_errors, 0..1, 2..5)
      end
    end
  end
end
