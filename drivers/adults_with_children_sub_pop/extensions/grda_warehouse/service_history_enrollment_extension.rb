###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :adults_with_children, -> do
        where(
          she_t[:age].gteq(18).and(she_t[:other_clients_under_18].gt(0)).
          or(she_t[:age].lt(18).
           and(
             she_t[:other_clients_between_18_and_25].gt(0).
             or(she_t[:other_clients_over_25].gt(0)),
           )),
        )
      end

      scope :family, -> do
        adults_with_children
      end

      scope :family_parents, -> do
        adults_with_children.heads_of_households
      end

      scope :parenting_youth, -> do
        family_parents.where(age: 18..24)
      end

      scope :youth_families, -> do
        adults_with_children.where(other_clients_over_25: 0).
          where(age: 0..24) # remove unknown aged clients
      end
    end
  end
end
