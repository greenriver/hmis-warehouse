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