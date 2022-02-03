###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HealthController < ApplicationController
  include HealthAuthorization
  include HealthPatient
end
