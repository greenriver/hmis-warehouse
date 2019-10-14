###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::Help < GrdaWarehouseBase
  acts_as_paranoid
  has_paper_trail

  scope :sorted, -> do
    order(title: :asc)
  end

  def self.cleaned_path controller_path:, action_name:
    "#{controller_path}/#{action_name}"
  end

  def self.for_path controller_path:, action_name:
    find_by(path: cleaned_path(controller_path: controller_path, action_name: action_name))
  end

end