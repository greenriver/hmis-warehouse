###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Pilot
  class MetricsController < Window::Health::Pilot::MetricsController
    include ClientPathGenerator
    
  end
end