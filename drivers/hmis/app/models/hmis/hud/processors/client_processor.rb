###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ClientProcessor < Base
    # TODO move ClientInputTransformer logic into here

    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::Client
    end

    def information_date(_)
    end
  end
end
