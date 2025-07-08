###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A referral of an individual client to an opportunity
module Hmis::Ce
  class CustomReferralStatus < GrdaWarehouseBase
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    scope :viewable_by, ->(user) do
      # todo @martha - by data source?
    end
  end
end
