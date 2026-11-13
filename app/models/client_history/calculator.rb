###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientHistory::Calculator
  ServiceRow = Struct.new(:date, :record_type, :homeless, :literally_homeless)

  # HUD 3.917: a stay of 7+ nights in permanent or transitional housing is a full break
  # between occasions of homelessness.
  HOUSED_BREAK_NIGHTS = 7

  # HUD 3.917 treats 90+ days in an institution as a full break. Enrollment data cannot
  # tell an institutional stay from an unrecorded one, so the same threshold ends an
  # episode across any gap this long with no recorded nights.
  UNACCOUNTED_BREAK_NIGHTS = 90

  # Only one of several entries sharing an entry date starts an episode. The episode counters
  # in GrdaWarehouse::Hud::Client walk enrollments in this order and treat the first as an
  # episode already in progress, so they have to agree with #same_day_duplicate?
  def self.in_episode_order(enrollments)
    enrollments.sort_by { |e| [e.entry_date, *episode_tie_break_key(e)] }
  end

  private_class_method def self.episode_tie_break_key(enrollment)
    [
      enrollment.data_source_id.to_i,
      enrollment.enrollment_group_id.to_s,
      enrollment.id,
    ]
  end

  attr_reader :client, :enrollments

  # @param client [GrdaWarehouse::Hud::Client] destination client the enrollments belong to
  # @param enrollments [Enumerable<GrdaWarehouse::ServiceHistoryEnrollment>] entry records already loaded by the caller
  def initialize(client:, enrollments:)
    @client = client
    @enrollments = enrollments.to_a
  end

  # Nights with a countable service (real, plus extrapolated when SO days count as months).
  def dates_served(enrollment)
    types = GrdaWarehouse::Hud::Client.service_types
    rows_for(enrollment).select { |r| types.include?(r.record_type) }.map(&:date).uniq.sort
  end

  def most_recent_service_date(enrollment)
    if GrdaWarehouse::Config.get(:ineligible_uses_extrapolated_days)
      dates_served(enrollment).max
    else
      rows_for(enrollment).select { |r| r.record_type == 'service' }.map(&:date).max
    end
  end

  # An ES/SH/SO entry starts a new episode when the client's previous homeless night is
  # separated from it by a full 7-night break: 7+ consecutive nights housed in PH/TH, a gap of
  # 7+ nights in presumed permanent housing (exit destination or prior living situation),
  # or a gap of 90+ nights with nothing recorded.
  # When several ES/SH/SO entries share the entry date, at any projects, only the record .in_episode_order puts first is marked.
  #
  # @param enrollment [GrdaWarehouse::ServiceHistoryEnrollment] the entry being evaluated
  # @return [Boolean]
  def new_episode?(enrollment:)
    return false unless HudHelper.util.chronic_project_types.include?(enrollment.project_type)
    return false if same_day_duplicate?(enrollment)

    entry_date = enrollment.entry_date
    last_homeless_night = episode_homeless_dates.select { |d| d < entry_date }.max
    return true if last_homeless_night.nil?

    gap = ((last_homeless_night + 1)...entry_date)
    return true if consecutive_nights?(housed_dates.select { |d| gap.cover?(d) }, HOUSED_BREAK_NIGHTS)

    nights_between = gap_nights(entry_date, last_homeless_night)
    return true if nights_between >= HOUSED_BREAK_NIGHTS && presumed_permanently_housed?(enrollment, last_homeless_night)

    nights_between >= UNACCOUNTED_BREAK_NIGHTS
  end

  # Nights housed in permanent housing.
  def residential_dates
    @residential_dates ||= begin
      ph_types = HudHelper.util.residential_project_type_numbers_by_code[:ph]
      enrollments.select { |e| ph_types.include?(e.project_type) }.flat_map do |e|
        rows_for(e).select { |r| r.homeless == false }.map(&:date)
      end.compact.uniq
    end
  end

  # Homeless nights in ES/SH/SO, plus PH nights before move-in when the
  # client entered PH from a homeless situation.
  # TH nights are housed (see #housed_dates).
  private def episode_homeless_dates
    @episode_homeless_dates ||= enrollments.flat_map { |e| homeless_dates_for(e) }.uniq
  end

  private def homeless_dates_for(enrollment)
    @homeless_dates_for ||= {}
    @homeless_dates_for[enrollment.id] ||= begin
      rows = service_rows_for(enrollment)
      if HudHelper.util.residential_project_type_numbers_by_code[:ph].include?(enrollment.project_type)
        if HudHelper.util.homeless_situations(as: :prior).include?(living_situation_for(enrollment))
          # homeless is nil for PH nights before move-in, false after
          rows.select { |r| r.homeless.nil? }.map(&:date)
        else
          []
        end
      else
        rows.select { |r| r.literally_homeless == true }.map(&:date)
      end
    end
  end

  # Housed nights in PH after move-in, plus every night in TH.
  private def housed_dates
    @housed_dates ||= begin
      th_types = HudHelper.util.residential_project_type_numbers_by_code[:th]
      enrollments.flat_map do |e|
        rows = service_rows_for(e)
        if th_types.include?(e.project_type)
          rows.map(&:date)
        else
          rows.select { |r| r.homeless == false }.map(&:date)
        end
      end.uniq
    end
  end

  private def consecutive_nights?(dates, count)
    run = 0
    previous = nil
    dates.uniq.sort.each do |date|
      run = previous == date - 1 ? run + 1 : 1
      return true if run >= count

      previous = date
    end
    false
  end

  private def gap_nights(entry_date, last_homeless_night)
    (entry_date - last_homeless_night).to_i - 1
  end

  # Same-day ES/SH/SO entries, whether one stay recorded twice or distinct projects, would all
  # qualify; only the one .in_episode_order puts first starts the episode. Asking the ordering
  # rather than repeating its rule is what keeps this in step with the episode counters.
  private def same_day_duplicate?(enrollment)
    chronic_types = HudHelper.util.chronic_project_types
    same_day = enrollments.select do |e|
      e.entry_date == enrollment.entry_date && chronic_types.include?(e.project_type)
    end
    first = self.class.in_episode_order(same_day).first

    first.present? && first.id != enrollment.id
  end

  # Permanent housing that is not an HMIS enrollment from the new entry's prior living
  # situation, or the exit destination of the stay that holds the last homeless night.
  private def presumed_permanently_housed?(enrollment, last_homeless_night)
    return true if HudHelper.util.permanent_situations(as: :prior).include?(living_situation_for(enrollment))

    permanent_destinations = HudHelper.util.permanent_destinations
    enrollments.any? do |e|
      permanent_destinations.include?(e.destination) && homeless_dates_for(e).include?(last_homeless_night)
    end
  end

  private def living_situation_for(enrollment)
    enrollment.enrollment&.LivingSituation
  end

  private def service_rows_for(enrollment)
    rows_for(enrollment).select { |r| r.record_type == 'service' }
  end

  private def rows_for(enrollment)
    rows_by_enrollment_id.fetch(enrollment.id, [])
  end

  private def rows_by_enrollment_id
    @rows_by_enrollment_id ||= GrdaWarehouse::ServiceHistoryService.
      where(client_id: client.id, service_history_enrollment_id: enrollments.map(&:id)).
      pluck(:service_history_enrollment_id, :date, :record_type, :homeless, :literally_homeless).
      group_by(&:first).
      transform_values do |rows|
        rows.map { |_, date, record_type, homeless, literally_homeless| ServiceRow.new(date, record_type, homeless, literally_homeless) }
      end
  end
end
