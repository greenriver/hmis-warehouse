###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Concerns::HmisArelHelper
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

    def hs_t
      Hmis::Hud::HmisService.arel_table
    end

    def cs_t
      Hmis::Hud::CustomService.arel_table
    end

    def cst_t
      Hmis::Hud::CustomServiceType.arel_table
    end

    def csc_t
      Hmis::Hud::CustomServiceCategory.arel_table
    end

    def cfa_t
      Hmis::Form::CustomFormAnswer.arel_table
    end

    def cded_t
      Hmis::Form::CustomDataElementDefinition.arel_table
    end
  end

  included do
    delegate :cas_t, :wip_t, :ar_t, :hs_t, :cst_t, :csc_t, :cfa_t, :cded_t, to: 'self.class'
  end
end
