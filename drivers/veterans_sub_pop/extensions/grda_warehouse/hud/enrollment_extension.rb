module VeteransSubPop::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :veterans, ->  do
        joins(:client).merge(GrdaWarehouse::Hud::Client.veterans)
      end

      scope :veteran, -> do
        veterans
      end
    end
  end
end