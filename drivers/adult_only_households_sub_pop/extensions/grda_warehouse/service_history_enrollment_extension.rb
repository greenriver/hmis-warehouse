###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultOnlyHouseholdsSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :adult_only_households, -> do
        where(she_t[:age].gteq(18).and(she_t[:other_clients_under_18].eq(0)))
      end

      scope :individual_adult, -> do
        adult_only_households.where(individual_adult: true)
      end

      scope :unaccompanied_youth, -> do
        where(unaccompanied_youth: true)
      end
    end
  end
end
