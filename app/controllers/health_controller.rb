###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HealthController < ApplicationController
  include HealthAuthorization
  include HealthPatient
end
