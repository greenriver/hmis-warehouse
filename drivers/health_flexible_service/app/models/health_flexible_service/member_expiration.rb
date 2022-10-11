###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class MemberExpiration
    include ArelHelper

    def title
      'VPR Member Expiration'
    end

    def data
      report_scope_source.
        expired_before(Date.tomorrow).
        order(end_date: :desc)
    end

    def report_scope_source
      HealthFlexibleService::Vpr
    end
  end
end
