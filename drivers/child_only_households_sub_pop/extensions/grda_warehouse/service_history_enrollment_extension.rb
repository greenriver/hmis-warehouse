###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ChildOnlyHouseholdsSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :child_only_households, -> do
        where(she_t[:age].lt(18).and(she_t[:other_clients_between_18_and_25].eq(0)).and(she_t[:other_clients_over_25].eq(0)))
      end

      scope :parenting_juvenile, -> do
        where(parenting_juvenile: true)
      end

      scope :children_only, -> do
        child_only_households
      end

      scope :unaccompanied_minors, -> do
        where(unaccompanied_minor: true)
      end
    end
  end
end
