###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Link < ApplicationRecord
  def self.for(location)
    @cache ||= {}

    @cache[location] ||= where(location: location)
  end

  def available_locations
    {
      'Footer' => 'footer',
      'Menu' => 'menu',
    }.freeze
  end
end
