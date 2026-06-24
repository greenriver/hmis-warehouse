###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/file-storage.md
module GrdaWarehouse
  class File < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :user, optional: true
  end
end
