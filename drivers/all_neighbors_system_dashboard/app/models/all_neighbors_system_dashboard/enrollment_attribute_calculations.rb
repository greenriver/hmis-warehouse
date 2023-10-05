###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  module EnrollmentAttributeCalculations
    extend ActiveSupport::Concern

    included do
      # Maybe update Tableau to use HUD event numbers?
      SERVICE_CODE_ID = {
        1 => 433, # Referral to Prevention Assistance project
        # 2 => # Problem Solving/Diversion/Rapid Resolution intervention or service
        3 => 435, # Referral to scheduled Coordinated Entry Crisis Needs Assessment
        4 => 436, # Referral to scheduled Coordinated Entry Housing Needs Assessment
        5 => 437, # Referral to Post-placement/ follow-up case management
        6 => 438, # Referral to Street Outreach project or services
        7 => 439, # Referral to Housing Navigation project or services
        8 => 440, # Referral to Non-continuum services: Ineligible for continuum services
        9 => 441, # Referral to Non-continuum services: No availability in continuum services
        # 10 => # Referral to Emergency Shelter bed opening
        11 => 443, # Referral to Transitional Housing bed/unit opening
        12 => 444, # Referral to Joint TH-RRH project/unit/resource opening
        13 => 445, # Referral to RRH project resource opening
        14 => 446, # Referral to PSH project resource opening
        15 => 447, # Referral to Other PH project/unit/resource opening
        # 16 => 'Referral to emergency assistance/flex fund/furniture assistance',
        17 => 1114, # Referral to Emergency Housing Voucher (EHV)
        # 18 => # Referral to a Housing Stability Voucher
      }.freeze

      def household_type(enrollment)
        return 'Children Only' if enrollment.children_only?
        # The enrollment isn't children only, but contains at least one child
        return 'Adults and Children' if enrollment.other_clients_under_18.positive? ||
          (enrollment.age.present? && enrollment.age < 18)

        'Adults Only'
      end

      def prior_living_situation_category(enrollment)
        case enrollment.living_situation
        when 30, 17, 37, 8, 9, 99
          'Unknown'
        when 16
          'Unsheltered'
        when 1, 18, 2
          'Sheltered'
        when 15, 6, 7, 25, 4, 5
          'Institutional'
        when 29, 14, 32, 13, 27, 12, 22, 35, 36, 23, 26, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11
          'Housed'
        when 24
          'Deceased'
        else
          'ERROR'
        end
      end

      def exit_date(filter, enrollment)
        date = enrollment.exit_date
        return nil if date.present? && date > filter.end_date

        date
      end

      def adjusted_exit_date(filter, enrollment)
        [
          enrollment.exit_date,
          filter.end_date,
        ].compact.min
      end

      def exit_type(enrollment)
        case enrollment.destination
        when nil
          nil
        when 26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34
          'Permanent'
        when 6, 24, 15
          'Excludable'
        when 8, 9, 99, 30, 17
          'Unknown'
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

      def primary_race(enrollment)
        HudUtility.race(enrollment.client.pit_race, multi_racial: true)
      end

      def race_list(enrollment)
        enrollment.client.race_description
      end

      def ce_infos_for_batch(filter, batch)
        # Find the active enrollments in the CE Project set for the HoH of the enrollments in the batch
        ce_project_enrollments = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          where(project_id: GrdaWarehouse::Hud::Project.where(id: filter.secondary_project_ids).pluck(:project_id)).
          open_between(start_date: filter.start_date, end_date: filter.end_date).
          where(id: batch.map { |en| en.service_history_enrollment_for_head_of_household&.id }.compact)

        enrollments_by_hoh = ce_project_enrollments.
          preload(:client).
          group_by { |enrollment| [enrollment.client.personal_id, enrollment.data_source_id] }

        # Find the events for HoHs associated with the CE project enrollments above.
        # Due to the possibility of finding enrollments with the same id from other data sources, this may pull
        # more events than required, but they will end up in unused groups.
        ce_events = GrdaWarehouse::Hud::Event.
          where(enrollment_id: ce_project_enrollments.pluck(:enrollment_group_id), event: SERVICE_CODE_ID.keys, event_date: filter.range).
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
            enrollment.destination.in?([26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]) # From SPM M2
        end.sort_by(&:exit_date).
          index_by(&:client_id) # Index by selects the last item, should be chronologically the last exit

        # Find the any enrollments entered by the clients in the reporting range, pulls all enrollments, not just
        # the ones in the batch.
        enrollments_by_client = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          where(client_id: exited_enrollments.values.map(&:client_id), entry_date: filter.range).
          group_by(&:client_id)

        # Select the enrollments for the client that are candidates for return
        re_enrollments = enrollments_by_client.map do |client_id, enrollments|
          exit_date = exited_enrollments[client_id].exit_date
          re_enrollment = enrollments.sort_by(&:entry_date).detect do |enrollment|
            candidate_for_return?(exit_date, enrollment)
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
      private def candidate_for_return?(exit_date, enrollment)
        enrollment.entry_date + 14.days >= exit_date ||
          (enrollment.entry_date >= exit_date && !enrollment.project_type.in?(HudUtility2024.residential_project_type_numbers_by_code[:ph]))
      end

      def enrollment_data
        # Source ProjectIDs are used in the report
        project_ids_from_groups = GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids_from_secondary_project_groups).pluck(:project_id)
        member_ids = universe.members.where(a_t[:project_id].in(project_ids_from_groups)).pluck(:universe_membership_id)
        Enrollment.where(id: member_ids).to_a
      end
    end
  end
end
