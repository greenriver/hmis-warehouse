###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      scope :visible_to, ->(user) do
        viewable_by(user)
      end
    end
  end
end
