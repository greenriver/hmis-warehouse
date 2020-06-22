module VeteransSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :veterans, -> do
        where(VeteranStatus: 1)
      end
      scope :veteran, -> do
        veterans
      end
    end
  end
end
