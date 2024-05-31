require 'time'
require 'date'

# preserves legacy date/time formatting, deprecated in rails 7
#   Date.today.to_s => "Apr 21, 2024"
module LegacyRailsConversions
  def to_s
    # could call deprecation logger here
    to_fs
  end
end

class Time
  prepend LegacyRailsConversions
end

module ActiveSupport
  class TimeWithZone
    prepend LegacyRailsConversions
  end
end

class DateTime
  prepend LegacyRailsConversions
end

class Date
  prepend LegacyRailsConversions
end
