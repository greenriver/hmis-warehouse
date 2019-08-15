###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients::Youth
  class FollowUpsController < Window::Clients::Youth::FollowUpsController
    include ClientPathGenerator
  end
end