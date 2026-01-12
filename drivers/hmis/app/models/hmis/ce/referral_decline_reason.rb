###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce
  class ReferralDeclineReason < GrdaWarehouseBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    validates :key, presence: true, uniqueness: { scope: :data_source_id }
    validates :name, presence: true

    scope :viewable_by, ->(user) do
      where(data_source_id: user.hmis_data_source_id)
    end
  end
end
