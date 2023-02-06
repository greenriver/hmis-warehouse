###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ExitProcessor < Base
    def factory_name
      :exit_factory
    end

    def schema
      Types::HmisSchema::Exit
    end
  end
end
