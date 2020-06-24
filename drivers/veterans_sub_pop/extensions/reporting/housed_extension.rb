module VeteransSubPop::Reporting
  module HousedExtension
    extend ActiveSupport::Concern

    included do
      def client_source
        GrdaWarehouse::Hud::Client.destination.veterans
      end
    end
  end
end