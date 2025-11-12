###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Favorite < GrdaWarehouseBase
  belongs_to :user
  belongs_to :entity, polymorphic: true
end
