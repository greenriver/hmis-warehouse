###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients::Youth
  class IntakesController < Window::Clients::Youth::IntakesController
    include ClientPathGenerator
  end
end