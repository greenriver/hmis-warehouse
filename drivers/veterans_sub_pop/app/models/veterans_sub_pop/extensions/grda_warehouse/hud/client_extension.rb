###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module VeteransSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :veterans, -> do
        where(VeteranStatus: 1)
      end
      scope :veteran, -> do
        veterans
      end
    end
  end
end
