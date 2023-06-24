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

    def fd_t
      Hmis::Form::Definition.arel_table
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

    def hh_t
      Hmis::Hud::Household.arel_table
    end

    def cde_t
      Hmis::Hud::CustomDataElement.arel_table
    end

    def cded_t
      Hmis::Hud::CustomDataElementDefinition.arel_table
    end

    def ccn_t
      Hmis::Hud::CustomClientName.arel_table
    end

    def u_t
      Hmis::Unit.arel_table
    end

    def ut_t
      Hmis::UnitType.arel_table
    end

    def c_t
      Hmis::Hud::Client.arel_table
    end

    def p_t
      Hmis::Hud::Project.arel_table
    end

    def o_t
      Hmis::Hud::Organization.arel_table
    end
  end

  included do
    delegate :cas_t, :wip_t, :ar_t, :hs_t, :cst_t, :csc_t, :cde_t, :cded_t, :hh_t, :u_t, :ut_t, to: 'self.class'
  end
end
