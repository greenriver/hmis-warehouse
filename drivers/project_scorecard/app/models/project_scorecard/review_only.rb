###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module ReviewOnly
    extend ActiveSupport::Concern
    included do
      def ces_rejected_referral_percentage
        return nil unless [total_ces_referrals, accepted_ces_referrals].all?

        ((accepted_ces_referrals / total_ces_referrals.to_f) * 100).round
      end
    end
  end
end
