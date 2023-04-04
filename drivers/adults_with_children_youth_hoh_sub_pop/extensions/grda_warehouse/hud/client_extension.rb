###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenYouthHohSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :adults_with_children_youth_hoh, -> do
        where(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.adults_with_children_youth_hoh.
           where(she_t[:client_id].eq(c_t[:id])).arel.exists,
        )
      end
    end
  end
end
