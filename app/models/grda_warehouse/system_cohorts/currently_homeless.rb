###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class CurrentlyHomeless < Base
    def cohort_name
      'Currently Homeless'
    end

    def sync(processing_date: Date.current, date_window: 1.day)
      @processing_date = processing_date
      @date_window = date_window

      add_missing_clients

      remove_housed_clients
      remove_inactive_clients
      remove_no_longer_meets_criteria
    end

    private def inactive_date
      @processing_date - days_of_inactivity.days
    end

    private def candidate_enrollments
      @candidate_enrollments ||= begin
        homeless_clients = enrollment_source.
          homeless. # homeless clients
          ongoing(on_date: @processing_date). # who's enrollment is open today
          with_service_between(start_date: inactive_date, end_date: @processing_date). # who received service in the past 90 days
          where.not( # who didn't receive a non-homeless (housed) service on the processing date
            client_id: service_history_source.
              where(date: @processing_date, homeless: false).
              select(:client_id),
          ).
          where.not(client_id: moved_in_ph). # who aren't currently enrolled and moved-in to PH
          where.not(client_id: cohort_clients.select(:client_id)). # who aren't on the cohort currently
          group(:client_id).minimum(:first_date_in_program)

        # Client are actively homeless, or only enrolled in CE with their most-recent CLS indicating they are homeless
        homeless_clients.merge(active_enrollments_from_ce.pluck(:client_id, :first_date_in_program).to_h)
      end
    end

    private def moved_in_ph
      enrollment_source.ph.
        ongoing(on_date: @processing_date + 1.days).
        where(she_t[:move_in_date].lteq(@processing_date)).
        select(:client_id)
    end

    # Anyone with an ongoing homeless enrollment that is still "active" (seen in past 90 days)
    # used to prevent people from getting marked as housed when their exit destination is Permanent
    # but they are still active in a homeless project
    # NOTE: alternate approach would be to pull last 90 days of homeless service and look for
    # any after the exit date with a permanent destination.
    # As written, the client won't be marked housed until the homeless enrollment is exited, or
    # 90 days has elapsed since they received service.
    private def active_ongoing_homeless_enrollments
      enrollment_source.
        homeless. # homeless clients
        ongoing(on_date: @processing_date).
        with_service_between(start_date: inactive_date, end_date: @processing_date, service_scope: :homeless).
        where(client_id: cohort_clients.select(:client_id)).
        distinct.
        pluck(:client_id)
    end

    private def add_missing_clients
      # Newly identified (first homeless enrollment in the past 2 years)
      # for each client with ongoing enrollments not on cohort
      #   find max exit or move in prior to min start of ongoing
      # if no exit or move in within the 2 years before min start of ongoing - Newly identified
      # if exit was to permanent destination within 2 year range, or move in was within 2 year range  - Returned from housing
      # else Returned from inactive unless no service in INACTIVE period

      # for candidate clients, find the most recent previously closed enrollment
      previous_enrollments = enrollment_source.
        where(client_id: candidate_enrollments.keys).
        exit_within_date_range(start_date: (@processing_date - 2.years).to_date, end_date: @processing_date).
        order(last_date_in_program: :asc).
        pluck(:client_id, :last_date_in_program, :destination).
        map { |client_id, *rest| [client_id, rest] }.to_h # to_h picks the last, so ordering date asc gives most recent

      most_recent_service_dates = service_history_source.
        where(client_id: candidate_enrollments.keys).
        where(date: (@processing_date - 2.years).to_date..@processing_date).
        order(date: :desc).
        pluck(:client_id, :date, :homeless).
        group_by(&:shift)

      newly_identified = []
      returned_from_housing = []
      returned_from_inactive = []
      candidate_enrollments.each do |client_id, entry_date|
        previous_entry_date, previous_destination = previous_enrollments[client_id]
        services = most_recent_service_dates[client_id]
        most_recent_service = services&.map(&:first)&.max
        # should return an hash of date => [true, false] for homeless on most-recent date prior to the processing date
        last_services_prior_to_processing_date = services&.select { |date, _| date < @processing_date }&.deep_dup&.group_by(&:shift)&.max_by(&:first)&.last
        # if on the day prior, you had any housed service, we'll count you as having returned from housing
        last_services_prior_to_processing_date_was_housed = last_services_prior_to_processing_date&.flatten&.any?(false) || false
        # if we've never seen you before, or it's been 2 years between enrollments
        if previous_entry_date.blank? || previous_entry_date < entry_date - 2.years
          newly_identified << client_id
        # if we have seen you before, and your exit was to a permanent destination, or you had prior
        # housed service, then you are returning from housing
        elsif HudUtility2024.permanent_destinations.include?(previous_destination) || last_services_prior_to_processing_date_was_housed
          returned_from_housing << client_id
        # if you have service within the active window, you have returned from inactivity
        elsif most_recent_service.present? && most_recent_service >= @processing_date - days_of_inactivity.days
          returned_from_inactive << client_id
        end
      end

      add_clients(newly_identified, 'Newly identified')
      add_clients(returned_from_housing, 'Returned from housing')
      add_clients(returned_from_inactive, 'Returned from inactive')
    end

    private def remove_housed_clients
      # Housed (received a move-in date in a PH project prior to the processing date,
      #   or exited to a Permanent destination from one of their homeless projects).
      housed_service_on_processing_date = service_history_source.on_date(@processing_date).
        where(
          client_id: cohort_clients.select(:client_id),
          homeless: false,
        ).
        distinct.
        pluck(:client_id)

      # moved-in to PH - anyone with a move-in date prior to processing date and an SHS homeless false on the processing date
      moved_in = cohort_clients.joins(client: :service_history_enrollments).
        merge(enrollment_source.ph.where(she_t[:move_in_date].lt(@processing_date))).
        pluck(:client_id) & housed_service_on_processing_date

      # Most-recent exit was to a permanent destination, and no open homeless enrollments on the processing date with # SHS homeless true within 90 days of the processing date
      with_permanent_destination = cohort_clients.joins(client: :service_history_enrollments).
        merge(
          enrollment_source.where(she_t[:last_date_in_program].lteq(@processing_date)).
          exit_within_date_range(start_date: (@processing_date - 2.years).to_date, end_date: @processing_date),
        ).
        pluck(:client_id, she_t[:last_date_in_program], she_t[:destination]).
        group_by(&:shift).
        select { |_, exits| exits.max_by(&:first).last.in?(HudUtility2024.permanent_destinations) }.
        keys

      # keep anyone who is still receiving homeless service on the cohort
      with_permanent_destination.reject! { |id| id.in?(active_ongoing_homeless_enrollments) }
      remove_clients(moved_in | with_permanent_destination, 'Housed')
    end

    private def remove_inactive_clients
      # Inactive (hasn't been seen in a homeless project in N days, where N refers to the setting on the cohort.)
      # only look up until the processing date.
      inactive_client_ids = cohort_clients.pluck(:client_id) - active_client_ids
      remove_clients(inactive_client_ids, 'Inactive')
    end

    private def active_client_ids
      active_client_ids_from_homeless_enrollments + active_client_ids_from_ce
    end

    private def active_client_ids_from_homeless_enrollments
      with_homeless_enrollment.
        where(client_id: cohort_clients.select(:client_id)).
        joins(:service_history_services).
        where(shs_t[:date].between(inactive_date..@processing_date)).
        distinct.
        pluck(:client_id)
    end

    # Clients who only have one ongoing enrollment, that enrollment is in CE, and their most-recent CLS indicates they were homeless
    private def active_client_ids_from_ce
      @active_client_ids_from_ce ||= active_enrollments_from_ce.pluck(:client_id)
    end

    private def active_enrollments_from_ce
      @active_enrollments_from_ce ||= begin
        homeless_situations = HudUtility2024.homeless_situations(as: :current)
        only_one_ce_enrollment = enrollment_source.where(client_id: only_one_enrollment_client_ids).ce
        # Find the most-recent CLS, and limit the enrollments to where the most-recent CLS was homeless
        only_one_ce_enrollment.joins(enrollment: :current_living_situations).
          one_for_column(
            :InformationDate,
            direction: :desc,
            source_arel_table: cls_t,
            group_on: [:PersonalID, :data_source_id],
          ).where(cls_t[:CurrentLivingSituation].in(homeless_situations))
      end
    end

    private def only_one_enrollment_client_ids
      enrollment_source.ongoing(on_date: @processing_date).
        group(:client_id).
        having('count(client_id) = 1').
        select(:client_id)
    end

    private def with_homeless_enrollment
      enrollment_source.
        homeless.
        ongoing(on_date: @processing_date)
    end

    private def remove_no_longer_meets_criteria
      # No longer meets criteria, any of the following
      # 1. exited without a permanent destination and
      #  a. no ongoing homeless enrollments
      #  b. no ongoing CE where the most-recent CLS was homeless
      # 2. ongoing homeless with overlapping PH move in

      no_ongoing_homeless_enrollment = cohort_clients.joins(client: :service_history_enrollments).
        where(she_t[:last_date_in_program].lt(@processing_date)).
        where.not(client_id: with_homeless_enrollment.select(:client_id)).
        merge(enrollment_source.where.not(destination: HudUtility2024.permanent_destinations)).
        pluck(:client_id)

      # preserve anyone who still has (and only has) a CE enrollment indicating they are still homeless
      no_ongoing = no_ongoing_homeless_enrollment - active_client_ids_from_ce

      currently_moved_in_ph = enrollment_source.ongoing(on_date: @processing_date).ph.
        where(client_id: cohort_clients.select(:client_id)).
        where(she_t[:move_in_date].lt(@processing_date)).
        pluck(:client_id)
      remove_clients(no_ongoing | currently_moved_in_ph, 'No longer meets criteria')
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    private def service_history_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end
