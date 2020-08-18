module ChildOnlyHouseholdsSubPop::Reporting
  module HousedExtension
    extend ActiveSupport::Concern

    included do
      def client_source
        GrdaWarehouse::Hud::Client.destination.child_only_households
      end
    end
  end
end