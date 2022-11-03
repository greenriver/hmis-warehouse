###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Link < ApplicationRecord
  scope :for, ->(location) do
    where(location: location)
  end

  def available_locations
    {
      'Footer' => 'footer',
      'Menu' => 'menu',
    }.freeze
  end
end
