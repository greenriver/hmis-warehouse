###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module NonVeteransSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :non_veterans, -> do
        where(c_t[:VeteranStatus].not_eq(1).or(c_t[:VeteranStatus].eq(nil)))
      end

      scope :non_veteran, -> do
        non_veterans
      end
    end
  end
end
