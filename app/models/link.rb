###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Link < ApplicationRecord
  @cache_mutex = Mutex.new

  def self.for(location)
    @cache_mutex.synchronize do
      @cache ||= {}
      @cache[location] ||= where(location: location).to_a
    end
  end

  def self.invalidate_cache
    @cache_mutex.synchronize do
      @cache = nil
    end
  end

  def available_locations
    {
      'Footer' => 'footer',
      'Menu' => 'menu',
    }.freeze
  end
end
