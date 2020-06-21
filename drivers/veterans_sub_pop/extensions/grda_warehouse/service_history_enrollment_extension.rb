module VeteransSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :veterans, -> do
        joins(:client).merge(GrdaWarehouse::Hud::Client.veteran)
      end
    end
  end
end