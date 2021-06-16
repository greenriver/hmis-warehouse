###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::CommonQueries
  extend ActiveSupport::Concern

  included do
    def active_clients
      a_t[:active_client].eq(true)
    end

    def new_and_active_clients
      a_t[:active_client].eq(true).
        and(a_t[:new_client].eq(true))
    end

    def active_and_enrolled_clients
      a_t[:active_client].eq(true).
        and(a_t[:enrolled_client].eq(true))
    end

    def all_members
      Arel.sql('1 = 1')
    end

    private def adults
      a_t[:age].gteq(18)
    end

    def in_street_outreach
      a_t[:project_type].eq(4)
    end

    def in_services_only
      a_t[:project_type].eq(6)
    end

    def stayers
      a_t[:last_date_in_program].eq(nil).
        or(a_t[:last_date_in_program].gt(@report.end_date))
    end

    def leavers
      a_t[:last_date_in_program].lteq(@report.end_date)
    end

    def received_service(service)
    "jsonb_path_exists (#{a_t[:services].to_sql}, '$.* ? (@ == #{service})')"
    end
  end
end
