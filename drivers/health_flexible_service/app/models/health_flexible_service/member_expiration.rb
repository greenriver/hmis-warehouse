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
      vpr_t = HealthFlexibleService::Vpr.arel_table

      report_scope_source.
        select(report_scope_source.column_names + [vpr_t[:end_date]]).
        where(vpr_t[:open].eq(true).and(vpr_t[:end_date].lteq(Date.today))).
        order(vpr_t[:end_date].desc).
        preload(:flexible_services, :client).
        distinct
    end

    def report_scope_source
      ::Health::Patient.joins(:flexible_services)
    end
  end
end
