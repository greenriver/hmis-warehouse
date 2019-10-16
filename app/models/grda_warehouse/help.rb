###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::Help < GrdaWarehouseBase
  acts_as_paranoid
  has_paper_trail
  attr_accessor :location

  scope :sorted, -> do
    order(title: :asc)
  end

  validates_presence_of :controller_path, :action_name
  validates :external_url, url: { allow_blank: true, no_local: true }

  def self.cleaned_path controller_path:, action_name:
    "#{controller_path}/#{action_name}"
  end

  def self.for_path controller_path:, action_name:
    find_by(controller_path: controller_path, action_name: action_name)
  end

  def location
    @location = if external_url.blank?
      :internal
    else
      :external
    end
  end
end