###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AdultOnlyHouseholdsSubPop::Reporting
  module HousedExtension
    extend ActiveSupport::Concern

    included do
      def client_source
        GrdaWarehouse::Hud::Client.destination.adult_only_households
      end
    end
  end
end
