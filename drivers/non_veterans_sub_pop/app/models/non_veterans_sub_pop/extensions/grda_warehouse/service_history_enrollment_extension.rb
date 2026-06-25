###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module NonVeteransSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :non_veterans, -> do
        joins(:client).merge(GrdaWarehouse::Hud::Client.non_veterans)
      end

      scope :non_veteran, -> do
        non_veterans
      end
    end
  end
end
