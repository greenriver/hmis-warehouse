###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Logic from https://www.hudexchange.info/resource/5689/client-level-system-use-and-length-of-time-homeless-report/

module GrdaWarehouse::WarehouseReports
  class HudLot
    attr_accessor :filter

    def initialize(filter)
      @filter = filter
    end

    private def locations_by_date
      dates.merge!(ph_dates)
      dates.merge!(th_dates)
    end

    private def dates
      @dates ||= @filter.range.zip([]).to_h
    end

    private def ph_dates
      @ph_dates ||= ph_services.distinct.pluck(:date).map do |d|
        [
          d,
          'Permanent Housing'
        ]
      end
    end

    private def th_dates
      @th_dates ||= th_services.distinct.pluck(:date).map do |d|
        [
          d,
          'Transitional housing'
        ]
      end
    end

    private def literally_homeless_dates
      @literally_homeless_dates ||= literally_homeless_services.distinct.pluck(:date).map do |d|
        [
          d,
          'Documented street/shelter'
        ]
      end
    end

    private def services
      GrdaWarehouse::ServiceHistoryService.
        service_within_date_range(start_date: filter.start, end_date: filter.end).
    end

    private def ph_services
      @ph_services ||= services.permanent_housing.non_homeless
    end

    private def th_services
      @th_services ||= services.transitional_housing.non_homeless
    end

    private def literally_homeless_services
      @literally_homeless_services ||= services.homeless(chronic_types_only: true)
    end
  end
end
