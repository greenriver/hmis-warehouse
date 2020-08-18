module AdultsWithChildrenSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :adults_with_children, -> do
        where(
         GrdaWarehouse::ServiceHistoryEnrollment.entry.adults_with_children.
          where(she_t[:client_id].eq(c_t[:id])).arel.exists
        )
      end
    end
  end
end
