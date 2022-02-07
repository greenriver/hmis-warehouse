###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultOnlyHouseholdsSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :adult_only_households, -> do
        where(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.adult_only_households.
           where(she_t[:client_id].eq(c_t[:id])).arel.exists,
        )
      end

      scope :youth, ->(on: Date.current) do
        where(DOB: (on - 24.years .. on - 18.years))
      end

      scope :adult, ->(on: Date.current) do
        where(c_t[:DOB].lteq(on - 18.years))
      end
    end
  end
end
