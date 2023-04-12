###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# FIXME guessing here about MCI token
module GrdaWarehouse
  module RemoteCredentials
    class Token < GrdaWarehouse::RemoteCredential
      REFERRAL_SLUG = 'mci'.freeze
      def self.mci
        where(slug: REFERRAL_SLUG).first!
      end
    end
  end
end
