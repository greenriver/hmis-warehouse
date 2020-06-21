module NonVeteransSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :non_veterans, -> do
        where(
         GrdaWarehouse::ServiceHistoryEnrollment.entry.non_veterans.
          where(she_t[:client_id].eq(c_t[:id])).arel.exists
        )
      end
    end
  end
end
