###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Logic from https://www.hudexchange.info/resource/5689/client-level-system-use-and-length-of-time-homeless-report/

# NOTE: https://hmis-warehouse.dev.test/clients/99293/hud_lots

module GrdaWarehouse::WarehouseReports
  class HudLot
    attr_accessor :filter, :client

    def initialize(client:, filter: )
      @client = client
      @filter = filter
    end

    def locations_by_date
      @locations_by_date ||= begin
        l_dates = dates.dup
        l_dates.merge!(ph_dates)
        l_dates.merge!(th_dates)
        l_dates.merge!(literally_homeless_dates)
        l_dates.merge!(breaks(l_dates))
        l_dates
      end
    end

    private def dates
      @dates ||= @filter.range.zip([]).to_h
    end

    private def ph_dates
      @ph_dates ||= ph_services.distinct.pluck(:date).map do |d|
        [
          d,
          ph_stay,
        ]
      end.to_h
    end

    private def th_dates
      @th_dates ||= th_services.distinct.pluck(:date).map do |d|
        [
          d,
          th_stay,
        ]
      end.to_h
    end

    private def literally_homeless_dates
      @literally_homeless_dates ||= begin
        lit_dates = literally_homeless_services.distinct.order(date: :asc).pluck(:date).map do |d|
          [
            d,
            shelter_stay,
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
              extra_days[d] = shelter_stay
            end
          end
        end
        lit_dates.to_h.merge(extra_days)
      end
    end

    # A break is added any time a PH/TH stay is started between two street stays
    # and lasts more than 7 days
    private def breaks(un_processed_dates)
      breaks = {}
      a_dates = un_processed_dates.to_a
      present_dates = a_dates.select{|_, v| v.present?}
      present_dates.each_with_index do |(date, type), i|
        next if shelter_stay?(type)
        previous_i = i - 1
        next unless shelter_stay?(present_dates[previous_i].last)
        break unless present_dates.map(&:last)[i..].include?(shelter_stay)
        next if next_7_days_includes_shelter?(date, un_processed_dates)

        breaks[date] = break_marker
      end
      breaks
    end

    private def next_7_days_includes_shelter?(date, check_dates)
      (date..date + 7.days).map do |d|
        check_dates[d]
      end.include?(shelter_stay)
    end

    private def break_marker
      'Documented break entering TH/PH'
    end

    private def shelter_stay
      'Documented street/shelter'
    end

    private def shelter_stay?(type)
      type == shelter_stay
    end

    private def th_stay
      'Transitional housing'
    end

    private def ph_stay
      'Permanent Housing'
    end

    private def services
     client.service_history_services.
        service_within_date_range(start_date: filter.start, end_date: filter.end)
    end

    private def ph_services
      @ph_services ||= services.permanent_housing.non_homeless
    end

    private def th_services
      @th_services ||= services.transitional_housing
    end

    private def literally_homeless_services
      @literally_homeless_services ||= services.homeless(chronic_types_only: true)
    end
  end
end
