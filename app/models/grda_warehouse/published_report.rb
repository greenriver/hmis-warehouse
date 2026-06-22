###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class PublishedReport < GrdaWarehouseBase
    belongs_to :report, polymorphic: true
    belongs_to :user

    scope :published, -> { where(state: 'published') }
  end
end
