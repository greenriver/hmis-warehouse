###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class PublishedReport < GrdaWarehouseBase
    belongs_to :report, polymorphic: true
    belongs_to :user

    scope :published, -> { where(state: 'published') }
  end
end
