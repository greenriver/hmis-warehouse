###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseAlert < ApplicationRecord
  belongs_to :user, optional: true
  acts_as_paranoid

  scope :ordered, -> do
    order(created_at: :desc)
  end
end
