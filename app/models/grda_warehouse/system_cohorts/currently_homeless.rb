###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class CurrentlyHomeless < Base
    def cohort_name
      'Currently Homeless'
    end

    def sync
      add_missing_clients

      remove_housed_clients
      remove_inactive_clients
      remove_no_longer_meets_criteria
    end

    private def add_missing_clients
      # Newly identified (first homeless enrollment in the past 2 years)
      # for each client with ongoing enrollments not on cohort
      #   find max exit or move in prior to min start of ongoing
      # if no exit or move in within the 2 years before min start of ongoing - Newly identified
      # if exit was to permanent destination within 2 year range, or move in was within 2 year range  - Returned from housing
      # else Returned from inactive unless no service in INACTIVE period

      moved_in_ph = enrollment_source.
        ongoing.
        ph.
        where(she_t[:move_in_date].lt(Date.current)).
        select(:client_id)

      candidate_enrollments = enrollment_source.
        homeless.
        ongoing.
        with_service_between(start_date: inactive_date, end_date: Date.current).
        where.not(client_id: service_history_source.where(date: Date.yesterday, homeless: false).select(:client_id)).
        where.not(client_id: moved_in_ph).
        where.not(client_id: cohort_clients.select(:client_id)).
        group(:client_id).minimum(:first_date_in_program)

      previous_enrollments = enrollment_source.
        where(client_id: candidate_enrollments.keys).
        where.not(last_date_in_program: nil).
        order(last_date_in_program: :asc).
        pluck(:client_id, :last_date_in_program, :destination).
        map { |client_id, *rest| [client_id, rest] }.to_h

      most_recent_service_dates = service_history_source.
        where(client_id: candidate_enrollments.keys).
        group(:client_id).maximum(:date)

      newly_identified = []
      returned_from_housing = []
      returned_from_inactive = []

      candidate_enrollments.each do |client_id, enrollment_date|
        previous_service_date, previous_destination = previous_enrollments[client_id]
        if previous_service_date.blank? || previous_service_date < enrollment_date - 2.years
          newly_identified << client_id
        elsif HUD.permanent_destinations.include?(previous_destination) || previous_service_date < enrollment_date
          returned_from_housing << client_id
        elsif most_recent_service_dates[client_id] && most_recent_service_dates[client_id] >= Date.current - days_of_inactivity.days
          returned_from_inactive << client_id
        end
      end

      add_clients(newly_identified, 'Newly identified')
      add_clients(returned_from_housing, 'Returned from housing')
      add_clients(returned_from_inactive, 'Returned from inactive')
    end

    private def remove_housed_clients
      # Housed (received a move-in date in a PH project, or exited to a Permanent destination from one of their homeless projects).
      # Limit to enrollments started after date added to cohort
      cohort_enrollments = enrollment_source.where(
        client_id: cohort_clients.joins(client: :service_history_enrollments).
          where(she_t[:first_date_in_program].gt(c_client_t[:date_added_to_cohort])).
          select(:client_id),
      )

      moved_in = cohort_enrollments.ph.where.not(move_in_date: nil).pluck(:client_id)
      with_permanent_destination = cohort_enrollments.homeless.where(destination: HUD.permanent_destinations).pluck(:client_id)
      remove_clients(moved_in | with_permanent_destination, 'Housed')
    end

    private def remove_inactive_clients
      # Inactive (hasn't been seen in a homeless project in N days, where N refers to the setting on the cohort.)
      active_client_ids = enrollment_source.
        homeless.
        where(client_id: cohort_clients.select(:client_id)).
        joins(:service_history_services).
        where(shs_t[:date].gt(inactive_date)).
        distinct.
        pluck(:client_id)
      inactive_client_ids = cohort_clients.pluck(:client_id) - active_client_ids

      remove_clients(inactive_client_ids, 'Inactive')
    end

    private def remove_no_longer_meets_criteria
      # No longer meets criteria (exited without a permanent destination and no ongoing homeless enrollments.)
      # or ongoing homeless with overlapping PH move in
      no_ongoing = enrollment_source.
        homeless.
        where(client_id: cohort_clients.where.not(client_id: enrollment_source.ongoing.homeless.select(:client_id)).select(:client_id)).
        where.not(destination: HUD.permanent_destinations).
        pluck(:client_id)
      moved_in_ph = enrollment_source.ongoing.ph.
        where(client_id: cohort_clients.select(:client_id)).
        where(she_t[:move_in_date].lt(Date.current)).
        pluck(:client_id)
      remove_clients(no_ongoing | moved_in_ph, 'No longer meets criteria')
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    private def service_history_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end
