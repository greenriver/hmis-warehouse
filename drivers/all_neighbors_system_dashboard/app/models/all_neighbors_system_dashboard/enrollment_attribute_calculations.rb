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
        HudUtility2024.race(enrollment.client.pit_race, multi_racial: true)
      end

      def race_list(enrollment)
        enrollment.client.race_description
      end

      def ce_infos_for_batch(filter, batch)
        household_enrollments = household_enrollments(filter, batch)
        ce_events = ce_events(filter, household_enrollments)

        {}.tap do |h|
          batch.each do |housing_enrollment|
            # Find the earliest most recent active enrollment for the household in the CE Project set with an entry on or before
            # the the entry into housing, and if there is an exit, it is after the report start
            ce_enrollment = household_enrollments[[housing_enrollment.household_id, housing_enrollment.data_source_id]]&.
              select { |enrollment| enrollment.entry_date <= housing_enrollment.entry_date }&.
              first
            next unless ce_enrollment.present?

            h[housing_enrollment.id] = OpenStruct.new(
              entry_date: ce_enrollment&.entry_date,
              ce_event: ce_events[[ce_enrollment.enrollment.enrollment_id, ce_enrollment.enrollment.data_source_id]],
            )
          end
        end
      end

      private def household_enrollments(filter, enrollment_batch)
        # Collect household members enrollments, because household ids might not be unique between data sources,
        # we need to process this per data source. Pulls all enrollments for the household, not just the ones in
        # the batch since a household may span batches.
        batches_by_data_source = enrollment_batch.group_by(&:data_source_id)
        {}.tap do |h|
          batches_by_data_source.each do |data_source_id, batch|
            h.merge!(
              GrdaWarehouse::ServiceHistoryEnrollment.
              preload(:enrollment).
              entry.
              where(project_id: filter.secondary_project_ids).
              where(household_id: batch.map(&:household_id), data_source_id: data_source_id).
              open_between(start_date: filter.start_date, end_date: filter.end_date).
              order(she_t[:entry_date].desc).
              group_by { |enrollment| [enrollment.household_id, enrollment.data_source_id] },
            )
          end
        end
      end

      private def ce_events(filter, household_enrollments)
        # Due to the possibility of finding enrollments with ids from other data sources, this may pull
        # more events than required, but, they will end up in unused groups.
        GrdaWarehouse::Hud::Event.
          where(enrollment_id: household_enrollments.values.flatten.map { |she| she.enrollment.enrollment_id }).
          where(event: SERVICE_CODE_ID.keys, event_date: filter.range).
          order(event_date: :asc).
          group_by { |event| [event.enrollment_id, event.data_source_id] }.
          transform_values(&:last)
      end

      def return_dates_for_batch(filter, batch)
        # Find enrollments in the batch by client with an exit to a permanent destination as defined in SPM M2
        exited_enrollments = batch.
          select do |enrollment|
          enrollment.exit_date.present? &&
            enrollment.destination.in?([26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]) # From SPM M2
        end.sort_by(&:entry_date).reverse. # Order, so the earliest entry is last
          index_by(&:client_id) # Index by selects the last item

        # Find the any enrollments entered by the clients in the reporting range, pulls all enrollments, not just
        # the ones in the batch.
        enrollments_by_client = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          where(client_id: exited_enrollments.values.map(&:client_id), entry_date: filter.range).
          group_by(&:client_id)

        # Select the enrollments for the client that are candidates for return
        re_enrollments = enrollments_by_client.map do |client_id, enrollments|
          exit_date = exited_enrollments[client_id].exit_date
          transformed = enrollments.select do |enrollment|
            candidate_for_return?(exit_date, enrollment)
          end
          [client_id, transformed] if transformed.present? # Only include clients with candidates
        end.compact.to_h

        # Build a hash of exited enrollments to the earliest date of the clients return to homelessness
        {}.tap do |h|
          exited_enrollments.values.each do |housing_enrollment|
            candidates = re_enrollments[housing_enrollment.client_id]
            next unless candidates.present?

            h[housing_enrollment.id] = candidates.map(&:entry_date).max
          end
        end
      end

      # To be a candidate for return, the entry must be at last 14 days after the exit, unless the
      # exit is from PH, in which case there doesn't need to be a gap.
      private def candidate_for_return?(exit_date, enrollment)
        enrollment.entry_date + 14.days >= exit_date ||
          (enrollment.entry_date >= exit_date && !enrollment.project_type.in?(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]))
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
