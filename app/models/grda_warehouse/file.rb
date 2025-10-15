###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class File < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :user, optional: true
  end
end
