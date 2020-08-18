module AdultsWithChildrenSubPop::Reporting
  module HousedExtension
    extend ActiveSupport::Concern

    included do
      def client_source
        GrdaWarehouse::Hud::Client.destination.adults_with_children
      end
    end
  end
end