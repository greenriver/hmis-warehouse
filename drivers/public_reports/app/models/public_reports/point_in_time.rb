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
      public_reports_warehouse_reports_point_in_time_index_url(host: ENV.fetch('FQDN'))
    end

    def run_and_save!
      start_report
      complete_report
    end

    private def pit_count_dates
      year = filter_object.start.year
      dates = []
      while year < filter_object.end.year + 1
        d = Date.new(year, 1, -1)
        d -= (d.wday - 3) % 7
        dates << d
        puts d
        year += 1
      end
      dates.select { |date| date.between?(filter_object.start, filter_object.end) }
    end

    private def pit_counts
      GrdaWarehouse::ServiceHistoryService.where(homeless: true, date: date).count
    end

    private def start_report
      update(started_at: Time.current)
    end

    private def complete_report
      update(completed_at: Time.current)
    end
  end
end
