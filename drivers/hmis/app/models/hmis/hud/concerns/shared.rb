###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::Shared
  extend ActiveSupport::Concern
  include Hmis::Hud::Concerns::HasEnums
  include ::HmisStructure::Shared

  included do
    def as_warehouse
      "GrdaWarehouse::Hud::#{self.class.name.demodulize}".constantize.find(id)
    end
  end
end
