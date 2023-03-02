###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisArelHelper
  extend ActiveSupport::Concern
  include ArelHelper

  class_methods do
    def cas_t
      Hmis::Hud::CustomAssessment.arel_table
    end

    def wip_t
      Hmis::Wip.arel_table
    end

    def ar_t
      Hmis::ActiveRange.arel_table
    end
  end

  included do
    delegate :cas_t, :wip_t, :ar_t, to: 'self.class'
  end
end
