###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ReferralPostingProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::ReferralPosting
    end

    def information_date(_)
    end

    def assign_metadata
      # nothing to assign, `new_with_referral` handles setting basic details
    end
  end
end
