###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    def self.headers
      [
        'Medicaid ID',
        'Last Name',
        'First Name',
        'VPR Start Date',
        'VPR End Date',
      ]
    end

    def self.columns_for_export(vpr)
      [
        vpr.medicaid_id,
        vpr.last_name,
        vpr.first_name,
        vpr.planned_on,
        vpr.end_date,
      ]
    end
  end
end
