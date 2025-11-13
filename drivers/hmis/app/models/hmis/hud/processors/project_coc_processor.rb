###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class ProjectCoCProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::ProjectCoc
    end

    def information_date(_)
    end
  end
end
