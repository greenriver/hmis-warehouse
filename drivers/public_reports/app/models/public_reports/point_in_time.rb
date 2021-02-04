###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class PointInTime < Report
    acts_as_paranoid

    def title
      _('Point-in-Time Report Generator')
    end

    def url
      public_reports_warehouse_reports_point_in_time_index_path_url(host: ENV.fetch('FQDN'))
    end

    def run_and_save!
      update(started_at: Time.current)
    end
  end
end
