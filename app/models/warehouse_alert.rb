###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseAlert < ApplicationRecord
  belongs_to :user
  acts_as_paranoid

  scope :ordered, -> do
    order(created_at: :desc)
  end
end
