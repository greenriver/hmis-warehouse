###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/warehouse/files-and-documents.md
# @see docs/features/warehouse/warehouse-files-model.md
module GrdaWarehouse
  class File < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :user, optional: true
  end
end
