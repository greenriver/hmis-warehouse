###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientHistory::Calculator
  ServiceRow = Struct.new(:date, :record_type, :homeless)

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

  # Determines if the enrollment in question is the start of a new episode of homelessness.
  # A new episode occurs if:
  #  - The client has not been in a literally homeless project (ES, SH, SO) in the last 30 days
  #  - The client is not currently housed in PH
  #  - The client was housed for at least a week in the past 90 days
  #
  # @param enrollment [Object] the specific enrollment being evaluated
  # @return [Boolean] true if the enrollment constitutes a new episode, otherwise false
  def new_episode?(enrollment:)
    return false unless HudHelper.util.chronic_project_types.include?(enrollment.project_type)

    entry_date = enrollment.entry_date
    thirty_days_ago = entry_date - 30.days
    ninety_days_ago = entry_date - 90.days

    housed_dates = residential_dates
    currently_housed = housed_dates.include?(entry_date)
    housed_for_week_in_past_90_days = (housed_dates & (ninety_days_ago...entry_date).to_a).count > 7

    other_homeless = (homeless_dates & (thirty_days_ago...entry_date).to_a).present?

    return true if ! currently_housed && housed_for_week_in_past_90_days && ! other_homeless

    return ! other_homeless
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

  # Nights with a real (non-extrapolated) homeless service in a residential project.
  private def homeless_dates
    @homeless_dates ||= begin
      residential_types = HudHelper.util.residential_project_type_ids
      enrollments.select { |e| e.project_type.in?(residential_types) }.flat_map do |e|
        rows_for(e).select { |r| r.record_type == 'service' && r.homeless == true }.map(&:date)
      end.compact.uniq
    end
  end

  private def rows_for(enrollment)
    rows_by_enrollment_id.fetch(enrollment.id, [])
  end

  private def rows_by_enrollment_id
    @rows_by_enrollment_id ||= GrdaWarehouse::ServiceHistoryService.
      where(client_id: client.id, service_history_enrollment_id: enrollments.map(&:id)).
      pluck(:service_history_enrollment_id, :date, :record_type, :homeless).
      group_by(&:first).
      transform_values { |rows| rows.map { |_, date, record_type, homeless| ServiceRow.new(date, record_type, homeless) } }
  end
end
