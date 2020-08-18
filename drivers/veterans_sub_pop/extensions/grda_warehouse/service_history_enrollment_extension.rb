module VeteransSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :veterans, -> do
        joins(:client).merge(GrdaWarehouse::Hud::Client.veterans)
      end

      scope :veteran, -> do
        veterans
      end
    end
  end
end