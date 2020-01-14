###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ActivityLog < ApplicationRecord

  belongs_to :user

  scope :created_in_range, -> (range:) do
    where(created_at: range)
  end

  def clean_object_name
    item_model&.gsub('GrdaWarehouse::Hud::', '')
  end
end