###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
end
