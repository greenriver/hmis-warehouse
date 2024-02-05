###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteransSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :veterans, -> do
        joins(:client).merge(GrdaWarehouse::Hud::Client.veterans)
      end

      scope :veteran, -> do
        veterans
      end
    end
  end
end
