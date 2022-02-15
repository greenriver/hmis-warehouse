###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Logic from https://www.hudexchange.info/resource/5689/client-level-system-use-and-length-of-time-homeless-report/

module GrdaWarehouse::WarehouseReports
  class HudLot
    attr_accessor :filter, :client

    def initialize(client:, filter: )
      @client = client
      @filter = filter
    end

    # NOTE: locations by date should remain sorted by date asc as other actions depend on that.
    def locations_by_date
      @locations_by_date ||= begin
        l_dates = dates.dup
        l_dates.merge!(ph_dates)
        l_dates.merge!(th_dates)
        l_dates.merge!(literally_homeless_dates)
        l_dates.merge!(breaks(l_dates))
        l_dates.merge!(self_reported_homelessness(l_dates))
        l_dates.merge!(self_reported_breaks(l_dates))
        l_dates.merge!(set_unknowns(l_dates))
      end
    end

    def summary_by_month
      @summary_by_month ||= begin
        summary = {}
        locations_by_date.each do |date, type|
          key = [date.year, date.month]
          summary[key] ||= Set.new
          summary[key] << type
        end
        summary.sort_by{|k, _|}.reverse
      end
    end

    def details_by_range
      @details_by_range ||= begin
        details = []
        (start_date, current_location) = locations_by_date&.first
        locations_by_date.each_with_index do |(date, type), index|
          next_date = date + 1.days
          next_location = locations_by_date[next_date]
          # we've reached the end
          if next_location.blank?
            details << {
              start_date: start_date,
              end_date: date,
              type: current_location,
            }
          else
            next if type == current_location

            details << {
              start_date: start_date,
              end_date: date,
              type: current_location,
            }
            start_date = next_date
            current_location = next_location
          end
        end
        details.reverse
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
        end.to_h
        extra_days = {}
        # Fill in any gaps of < 7 days
        lit_dates.to_a.each_with_index do |(date, _), i|
          (next_date, _) = lit_dates.to_a[i + 1]
          next if next_date.blank? || next_date > filter.end

          if next_date < date + 7.days
            (date..next_date).each do |d|
              extra_days[d] = shelter_stay unless lit_dates.key?(d)
            end
          end
        end

        lit_dates.merge(extra_days).sort_by{|k,_| k}.to_h
      end
    end

    # A break is added any time a PH/TH stay is started between two street stays
    # and lasts more than 7 days
    # 1. Occurs between two Documented street/shelter dates 7 or more days apart
    # 2. AND does not include a Documented street/shelter date
    # 3. AND includes 7 or more consecutive days in permanent or transitional housing.

    private def breaks(un_processed_dates)
      breaks = {}
      a_dates = un_processed_dates.to_a
      dates_present = a_dates.select{|_, v| v.present?}
      dates_present.each_with_index do |(date, type), i|
        next if i.zero?
        next if shelter_stay?(type)
        previous_i = i - 1
        next unless shelter_stay?(dates_present[previous_i].last)
        break unless dates_present.map(&:last)[i..].include?(shelter_stay)
        next if next_7_days_includes?(shelter_stay, date: date, check_dates: un_processed_dates)
        # Since we already skipped if we had a shelter stay, just make sure we have
        # Something in all of the next seven days
        next unless next_7_days(date: date, check_dates: un_processed_dates).count(&:present?) == 8

        breaks[date] = break_marker
      end
      breaks
    end

    # For any date not already assigned a status, or which has a status of Self-reported street/shelter, assign a status of Self- reported/potential break for the date immediately prior to Project Start Date for any continuum enrollment where all of the following are true:
      # Project Start Date minus 1 day is between any two dates with a status of Documented street/shelter or Self- reported street/shelter.
      # AND Living Situation is one of the following:
        # a. Institutional stay of more than 90 days
        # b. OR Transitional or permanent housing situation of 7 nights or more

    private def self_reported_breaks(un_processed_dates)
      self_reported_breaks = {}
      entries.find_each do |en|
        project = en.project
        date_prior_to_entry = en.first_date_in_program - 1.days
        next unless project.coc_funded?
        # next unless institutional_stay_longer_than_90_days?(en) || transitional_or_permanent_longer_than_7_days?(en)
        next unless un_processed_dates[date_prior_to_entry]&.include?(any_shelter_stay)

        # Going backward, find the maximum blank date
        # From there, find the maximum 'street/shelter' and TH/PH
        # If the TH/PH date is > street shelter, do nothing
        # If the street shelter is present, set a self reported break
        max_unknown_date = un_processed_dates.select{|d, type| d < date_prior_to_entry && type.blank?}.keys.max
        next unless max_unknown_date.present?

        max_th_ph_date = un_processed_dates.select{|d, type| d < max_unknown_date && type&.in?([th_stay, ph_stay])}.keys.max
        max_es_date = un_processed_dates.select{|d, type| d < max_unknown_date && type&.include?(any_shelter_stay)}.keys.max
        # Must fall between two street/shelter
        next unless max_es_date.present?
        # If we have a PH/TH date, we the street date must be newer
        next if max_th_ph_date.present? && max_th_ph_date > max_es_date

        self_reported_breaks[date_prior_to_entry] = self_reported_break
      end
      self_reported_breaks
    end

    private def self_reported_homelessness(un_processed_dates)
      self_report_dates = {}
      entries.find_each do |en|
        enrollment = en.enrollment
        project = en.project
        # If we didn't claim to have pre-enrtry homelessness ignore it
        next unless enrollment.DateToStreetESSH.present?
        # Or if the dates don't work
        next unless enrollment.DateToStreetESSH < en.first_date_in_program

        if en.ph?
          # Homeless Situation
          if HUD.homeless_situations(as: :prior).include?(enrollment&.LivingSituation)

            # Add any dates between DateToStreetESSH and the MoveInDate
            count_until = [enrollment.MoveInDate, en.last_date_in_program, filter.end].compact.min
            (enrollment.DateToStreetESSH..count_until).each do |d|
              self_report_dates[d] = self_reported_shelter
            end
            # Institutional Situations
          elsif HUD.institutional_situations(as: :prior).include?(enrollment&.LivingSituation)
            next unless enrollment.LOSUnderThreshold == 1 && enrollment.PreviousStreetESSH == 1

            # Add any dates between DateToStreetESSH and the MoveInDate
            count_until = [enrollment.MoveInDate, en.last_date_in_program, filter.end].compact.min
            (enrollment.DateToStreetESSH..count_until).each do |d|
              self_report_dates[d] = self_reported_shelter
            end
          end
        else
          next unless project.ContinuumProject == 1
          next unless en.computed_project_type.in?([1, 2, 4, 8, 11, 12, 14])
          # Homeless enrollment, or institutional stay
          if en.es? || en.sh? || en.so? || HUD.institutional_situations(as: :prior).include?(enrollment&.LivingSituation)
            (enrollment.DateToStreetESSH..en.first_date_in_program).each do |d|
              self_report_dates[d] = self_reported_shelter
            end
          else
            next unless enrollment.LOSUnderThreshold == 1 && enrollment.PreviousStreetESSH == 1

            (enrollment.DateToStreetESSH..en.first_date_in_program).each do |d|
              self_report_dates[d] = self_reported_shelter
            end
          end
        end
      end
      # Remove any dates that are already set, or fall outside of the range
      self_report_dates.each do |d, _|
        self_report_dates.delete(d) if d < filter.start || d > filter.end || un_processed_dates[d].present?
      end
      self_report_dates
    end

    private def set_unknowns(un_processed_dates)
      unknown_dates = {}
      un_processed_dates.each do |d, type|
        unknown_dates[d] = unknown if type.blank?
      end
      unknown_dates
    end

    private def next_7_days_includes?(stay_type, date:, check_dates:)
      next_7_days(date: date, check_dates: check_dates).include?(stay_type)
    end

    private def next_7_days(date:, check_dates:)
      (date..date + 7.days).map do |d|
        check_dates[d]
      end
    end

    private def institutional_stay_longer_than_90_days?(entry)
      entry.enrollment.LivingSituation.in?(HUD.institutional_situations(as: :prior)) &&
        entry.enrollment.LengthOfStay.in?([4, 5])
    end

    private def transitional_or_permanent_longer_than_7_days?(entry)
      entry.enrollment.LivingSituation.in?(HUD.temporary_and_permanent_housing_situations(as: :prior)) &&
        entry.enrollment.LengthOfStay.in?([2, 3, 4, 5])
    end


    def break_marker
      'Documented break entering TH/PH'
    end

    def shelter_stay
      'Documented street/shelter'
    end

    def shelter_stay?(type)
      type == shelter_stay
    end

    def any_shelter_stay
      'street/shelter'
    end

    def th_stay
      'Transitional housing'
    end

    def ph_stay
      'Permanent Housing'
    end

    def self_reported_shelter
      'Self-reported street/shelter'
    end

    def self_reported_break
      'Self-reported/potential break'
    end

    def unknown
      'Unknown'
    end

    # While the service dates may come from enrollments started before the start_date
    # the self-report would only ever count if it included a date within the range
    # which is only possible if the entry assessment occured within the range
    private def entries
      client.service_history_enrollments.
        with_service_between(start_date: filter.start, end_date: filter.end).
        started_between(start_date: filter.start, end_date: filter.end).
        order(first_date_in_program: :asc).
        joins(:enrollment, :project).
        left_outer_joins(enrollment: :exit).
        eager_load(:project, enrollment: [:exit, :project])
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
