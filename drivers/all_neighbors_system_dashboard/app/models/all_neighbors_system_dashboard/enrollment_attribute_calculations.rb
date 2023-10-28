###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  module EnrollmentAttributeCalculations
    extend ActiveSupport::Concern

    included do
      SERVICE_CODE_IDS = [
        1, # Referral to Prevention Assistance project
        # 2 => # Problem Solving/Diversion/Rapid Resolution intervention or service
        3, # Referral to scheduled Coordinated Entry Crisis Needs Assessment
        4, # Referral to scheduled Coordinated Entry Housing Needs Assessment
        5, # Referral to Post-placement/ follow-up case management
        6, # Referral to Street Outreach project or services
        7, # Referral to Housing Navigation project or services
        8, # Referral to Non-continuum services: Ineligible for continuum services
        9, # Referral to Non-continuum services: No availability in continuum services
        # 10 => # Referral to Emergency Shelter bed opening
        11, # Referral to Transitional Housing bed/unit opening
        12, # Referral to Joint TH-RRH project/unit/resource opening
        13, # Referral to RRH project resource opening
        14, # Referral to PSH project resource opening
        15, # Referral to Other PH project/unit/resource opening
        # 16 => 'Referral to emergency assistance/flex fund/furniture assistance',
        17, # Referral to Emergency Housing Voucher (EHV)
        # 18 => # Referral to a Housing Stability Voucher
      ].freeze

      SHELTERED_SITUATIONS = [
        101,
        118,
        302,
      ].freeze

      UNSHELTERED_SITUATIONS = [
        116,
      ].freeze

      UNKNOWN_SITUATIONS = [
        30,
        17,
        37,
        8,
        9,
        99,
      ].freeze

      DECEASED_SITUATIONS = [
        24,
      ].freeze

      UNKNOWN_DESTINATIONS = [
        30,
        17,
        8,
        9,
        99,
      ].freeze

      EXCLUDEABLE_DESTINATIONS = [
        206,
        24,
        215,
      ].freeze

      POSITIVE_DIVERSION_DESTINATIONS = [
        215,
        329,
        312,
        313,
        225,
        332,
        426,
        411,
        421,
        410,
        435,
        422,
        423,
      ].freeze

      def household_type(enrollment)
        return 'Children Only' if enrollment.children_only?
        # The enrollment isn't children only, but contains at least one child
        return 'Adults and Children' if enrollment.other_clients_under_18.positive? ||
          (enrollment.age.present? && enrollment.age < 18)

        'Adults Only'
      end

      def prior_living_situation_category(enrollment)
        case enrollment.living_situation
        when *UNKNOWN_SITUATIONS
          'Unknown Situation'
        when *UNSHELTERED_SITUATIONS
          'Unsheltered'
        when *SHELTERED_SITUATIONS
          'Sheltered'
        when HudUtility2024::SITUATION_INSTITUTIONAL_RANGE
          'Institutional'
        when HudUtility2024::SITUATION_TEMPORARY_RANGE, HudUtility2024::SITUATION_PERMANENT_RANGE
          'Housed'
        when *DECEASED_SITUATIONS
          'Deceased'
        else
          'ERROR'
        end
      end

      def exit_date(filter, enrollment)
        date = enrollment.exit_date
        # ignore any exit date after the report end
        return nil if date.present? && date > filter.end_date

        date
      end

      # Exit date if it occurs before the end of the report, or report end date
      def adjusted_exit_date(filter, enrollment)
        [
          enrollment.exit_date,
          filter.end_date,
        ].compact.min
      end

      def exit_type(filter, enrollment)
        # Don't admin any exit types, unless we have an exit before report end
        return nil unless exit_date(filter, enrollment).present?

        # If this is a "diversion" project, we'll treat exit destination differently
        diversion = enrollment.project.id.in?(filter.secondary_project_ids)
        return 'Permanent' if diversion && enrollment.destination.in?(POSITIVE_DIVERSION_DESTINATIONS)

        case enrollment.destination
        when nil
          nil
        when HudUtility2024::SITUATION_PERMANENT_RANGE
          'Permanent'
        when *EXCLUDEABLE_DESTINATIONS
          'Excludable'
        when *UNKNOWN_DESTINATIONS
          'Unknown Destination'
        else
          'Non-Permanent'
        end
      end

      def relationship(enrollment)
        case enrollment.relationship_to_ho_h
        when 1
          'SL'
        when 2
          'DC'
        when 3
          'SP'
        when 4
          'F'
        when 5
          'O'
        end
      end

      def gender(enrollment)
        HudUtility2024.gender(enrollment.client.gender_binary)
      end

      # Need to align with the census races (roughly)
      # so we're going to pick randomly if a client has more than one
      # race, and we'll convert all RaceNone to Unknown Race
      def primary_race(enrollment)
        HudUtility2024.race(enrollment.client.pit_race, multi_racial: true) || "Doesn't know, prefers not to answer, or not collected"
      end

      def race_list(enrollment)
        enrollment.client.race_description
      end

      def ce_infos_for_batch(filter, batch)
        # Find the active enrollments with appropriate events for the HoH of the enrollments in the batch
        ce_project_enrollments = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          joins(enrollment: :events).
          merge(GrdaWarehouse::Hud::Event.where(event: SERVICE_CODE_IDS, event_date: filter.range)).
          open_between(start_date: filter.start_date, end_date: filter.end_date).
          where(id: batch.map { |en| en.service_history_enrollment_for_head_of_household&.id }.compact)

        enrollments_by_hoh = ce_project_enrollments.
          distinct.
          preload(:client).
          group_by { |enrollment| [enrollment.client.personal_id, enrollment.data_source_id] }

        # Find the events for HoHs associated with the CE project enrollments above.
        # Due to the possibility of finding enrollments with the same id from other data sources, this may pull
        # more events than required, but they will end up in unused groups.
        ce_events = GrdaWarehouse::Hud::Event.
          where(enrollment_id: ce_project_enrollments.pluck(:enrollment_group_id), event: SERVICE_CODE_IDS, event_date: filter.range).
          order(event_date: :asc).
          group_by { |event| [event.personal_id, event.data_source_id] }

        {}.tap do |h|
          batch.each do |housing_enrollment|
            ce_enrollment = enrollments_by_hoh[[housing_enrollment.head_of_household_id, housing_enrollment.data_source_id]]&.
              select { |enrollment| enrollment.entry_date <= housing_enrollment.entry_date }&.
              first
            next unless ce_enrollment&.enrollment.present? && ce_enrollment&.client.present?

            h[housing_enrollment.id] = OpenStruct.new(
              entry_date: ce_enrollment&.entry_date,
              ce_event: ce_events[[ce_enrollment.client.personal_id, ce_enrollment.enrollment.data_source_id]],
            )
          end
        end
      end

      def return_dates_for_batch(filter, batch)
        # Find enrollments in the batch by client with an exit to a permanent destination as defined in SPM M2
        exited_enrollments = batch.
          select do |enrollment|
          enrollment.exit_date.present? &&
            enrollment.destination.in?(HudUtility2024::SITUATION_PERMANENT_RANGE) # From SPM M2
        end.sort_by(&:exit_date).
          index_by(&:client_id) # Index by selects the last item, should be chronologically the last exit

        # Find the any enrollments entered by the clients within the reporting period and the year after so we can find anyone who returned with a year of exiting
        enrollments_by_client = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          where(client_id: exited_enrollments.values.map(&:client_id), entry_date: (filter.start_date .. filter.end_date + 1.years)).
          group_by(&:client_id)

        # Select the enrollments for the client that are candidates for return
        re_enrollments = enrollments_by_client.map do |client_id, enrollments|
          housed_exit_date = exited_enrollments[client_id].exit_date
          re_enrollment = enrollments.sort_by(&:entry_date).detect do |enrollment|
            candidate_for_return?(housed_exit_date, enrollment)
          end
          [client_id, re_enrollment] if re_enrollment.present? # Only include clients with candidates
        end.compact.to_h

        # Build a hash of exited enrollments to the earliest date of the clients return to homelessness
        {}.tap do |h|
          exited_enrollments.values.each do |housing_enrollment|
            candidate = re_enrollments[housing_enrollment.client_id]
            next unless candidate.present?

            h[housing_enrollment.id] = candidate.entry_date
          end
        end
      end

      # To be a candidate for return, the entry must be at last 14 days after the exit, unless the
      # exit is from PH, in which case there doesn't need to be a gap.
      # Additionally, the re-entry must be within 365 days of the exit
      private def candidate_for_return?(housed_exit_date, enrollment)
        re_entry_window_start = if enrollment.project_type.in?(HudUtility2024.residential_project_type_numbers_by_code[:ph])
          housed_exit_date
        else
          housed_exit_date + 14.days
        end
        re_entry_window = (re_entry_window_start .. re_entry_window_start + 1.years)
        enrollment.entry_date.in?(re_entry_window)
      end
    end
  end
end
