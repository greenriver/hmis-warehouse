###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ReferralRequestProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::ReferralRequest
    end

    def information_date(_)
    end

    # FIXME: there's probably a better way
    # MAP = {
    #   'unitType' => 'unit_type_id',
    # }.freeze
    # def hud_name(field)
    #   MAP.fetch(field, field.underscore)
    # end
  end
end
