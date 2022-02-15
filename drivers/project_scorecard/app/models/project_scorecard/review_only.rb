###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module ReviewOnly
    extend ActiveSupport::Concern
    included do
      def ces_rejected_referral_percentage
        return nil unless [total_ces_referrals, accepted_ces_referrals].all?
        return nil if total_ces_referrals.zero?

        ((accepted_ces_referrals / total_ces_referrals.to_f) * 100).round
      end

      def ces_rejected_score
        score(ces_rejected_referral_percentage, 0..10)
      end

      def site_monitoring_score
        case site_monitoring
        when 'No Findings'
          10
        when 'Findings but Resolved'
          5
        else
          0
        end
      end
    end
  end
end
