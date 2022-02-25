###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenTwentyfivePlusHohSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :adults_with_children_twentyfive_plus_hoh, -> do
        where(
          she_t[:age].gteq(25).
            and(she_t[:head_of_household].eq(true)).
            and(she_t[:other_clients_under_18].gt(0)),
        )
      end
    end
  end
end
