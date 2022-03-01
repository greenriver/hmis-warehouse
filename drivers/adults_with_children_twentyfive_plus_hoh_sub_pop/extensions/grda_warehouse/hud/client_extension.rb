###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenTwentyfivePlusHohSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :adults_with_children_twentyfive_plus_hoh, -> do
        where(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.adults_with_children_twentyfive_plus_hoh.
           where(she_t[:client_id].eq(c_t[:id])).arel.exists,
        )
      end
    end
  end
end
