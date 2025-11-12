###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  class ReferralsController < HmisExternalApis::BaseController
    def create
      # Create request log
      request_log

      respond_with_errors(['This endpoint is no longer available'])
    end
  end
end
