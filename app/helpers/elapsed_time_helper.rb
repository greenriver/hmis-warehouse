###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ElapsedTimeHelper
  def elapsed_time(total_seconds, decimal_places: 0)
    return unless total_seconds

    d = total_seconds / 86_400
    h = total_seconds / 3600 % 24
    m = total_seconds / 60 % 60
    s = (total_seconds % 60).round(decimal_places)
    if d >= 1
      format('%id%ih%im%ss', d, h, m, s)
    elsif h >= 1
      format('%ih%im%ss', h, m, s)
    elsif m >= 1
      format('%im%ss', m, s)
    else
      format('%ss', s)
    end
  end

  def precise_distance_of_time(seconds)
    return 'less than a minute' if seconds.to_f < 60

    # Convert to integer for consistent division
    seconds = seconds.to_i
    parts = []

    days, seconds = seconds.divmod(1.day.to_i)
    parts << "#{days} #{'day'.pluralize(days)}" if days > 0

    hours, seconds = seconds.divmod(1.hour.to_i)
    parts << "#{hours} #{'hour'.pluralize(hours)}" if hours > 0

    minutes = seconds / 1.minute.to_i
    parts << "#{minutes} #{'minute'.pluralize(minutes)}" if minutes > 0

    parts.join(', ')
  end
end
