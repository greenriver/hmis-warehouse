###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module CeParticipation
    extend ActiveSupport::Concern
    included do
      def lease_up_score
        score(days_to_lease_up, 0..30, 31..45)
      end

      def accepted_referrals_percentage
        return nil unless [accepted_referrals, number_referrals].all?
        return nil if number_referrals.zero?

        ((accepted_referrals / number_referrals.to_f) * 100).round
      end

      def accepted_referrals_score
        score(accepted_referrals_percentage, 90..Float::INFINITY)
      end
    end
  end
end
