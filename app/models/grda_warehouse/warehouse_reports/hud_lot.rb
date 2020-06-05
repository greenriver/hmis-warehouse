###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Logic from https://www.hudexchange.info/resource/5689/client-level-system-use-and-length-of-time-homeless-report/

module GrdaWarehouse::WarehouseReports
  class HudLot
    attr_accessor :filter, :client

    def initialize(client:, filter: )
      @client = client
      @filter = filter
    end

    def locations_by_date
      dates.merge!(ph_dates)
      dates.merge!(th_dates)
      dates.merge!(literally_homeless_dates)
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
      end.to_h
    end

    private def th_dates
      @th_dates ||= th_services.distinct.pluck(:date).map do |d|
        [
          d,
          'Transitional housing'
        ]
      end.to_h
    end

    private def literally_homeless_dates
      @literally_homeless_dates ||= begin
        lit_dates = literally_homeless_services.distinct.order(date: :asc).pluck(:date).map do |d|
          [
            d,
            'Documented street/shelter'
          ]
        end
        extra_days = {}
        # Fill in any gaps of < 7 days
        lit_dates.select{|_, v| v.present?}.each_with_index do |(date, _), i|
          next_i = i + 1
          next if lit_dates.count == next_i
          next_date = lit_dates[next_i].first
          if next_date < date + 7.days
            (date..next_date).each do |d|
              extra_days[d] = 'Documented street/shelter'
            end
          end
        end
        lit_dates.to_h.merge(extra_days)
      end
    end

    private def services
     client.service_history_services.
        service_within_date_range(start_date: filter.start, end_date: filter.end)
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
