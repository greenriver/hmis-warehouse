###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module NonVeteransSubPop::Reporting
  module HousedExtension
    extend ActiveSupport::Concern

    included do
      def client_source
        GrdaWarehouse::Hud::Client.destination.non_veterans
      end
    end
  end
end
