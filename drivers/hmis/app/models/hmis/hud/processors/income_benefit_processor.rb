###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class IncomeBenefitProcessor < Base
    def factory_name
      :income_benefit_factory
    end

    def schema
      Types::HmisSchema::IncomeBenefit
    end
  end
end
