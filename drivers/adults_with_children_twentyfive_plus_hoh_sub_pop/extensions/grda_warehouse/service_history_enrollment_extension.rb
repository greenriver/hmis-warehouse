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

      scope :family, -> do
        adults_with_children_twentyfive_plus_hoh
      end

      scope :family_parents, -> do
        adults_with_children_twentyfive_plus_hoh.heads_of_households
      end

      scope :parenting_youth, -> do
        family_parents.where(age: 18..24)
      end

      scope :youth_families, -> do
        adults_with_children_twentyfive_plus_hoh.where(other_clients_over_25: 0).
          where(age: 0..24) # remove unknown aged clients
      end
    end
  end
end
