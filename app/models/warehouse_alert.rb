###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class WarehouseAlert < ActiveRecord::Base
  belongs_to :user
  acts_as_paranoid

  scope :ordered, -> do
    order(created_at: :desc)
  end
end
