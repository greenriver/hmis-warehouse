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
        date = enrollment.exit_date
        return filter.end_date if date.blank?
        return nil if date.present? && date > filter.end_date

        date
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
        HudUtility.gender(enrollment.client.gender_binary)
      end

      def primary_race(enrollment)
        HudUtility.race(enrollment.client.pit_race, multi_racial: true)
      end

      def race_list(enrollment)
        enrollment.client.race_description
      end

      def ce_info(filter, housing_enrollment)
        household_enrollments = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          where(household_id: housing_enrollment.household_id, data_source_id: housing_enrollment.data_source_id).
          where(she_t[:exit_date].eq(nil).or(she_t[:exit_date].gteq(filter.start_date)))

        # Find the earliest most recent active enrollment for the household in the CE Project set with an entry on or before
        # the the entry into housing, and if there is an exit, it is after the report start
        ce_enrollment = household_enrollments.
          where(entry_date: (.. housing_enrollment.entry_date)).
          where(project_id: filter.secondary_project_ids).
          order(entry_date: :asc).
          index_by(&:client_id). # index keeps last value, so this will find the most recent enrollment for each client
          values.min_by(&:entry_date) # find the earliest enrollment

        # Find the most recent referral event associated with any active household enrollment in the reporting period
        ce_event = GrdaWarehouse::Hud::Event.
          where(enrollment_id: household_enrollments.map { |she| she.enrollment.enrollment_id }).
          where(event: SERVICE_CODE_ID.keys, event_date: filter.range).
          order(event_date: :desc).first # most recent event

        OpenStruct.new(
          entry_date: ce_enrollment&.entry_date,
          ce_event: ce_event,
        )
      end

      def return_date(filter, housing_enrollment)
        # Find the entry date into a homeless project if the client exits the housing enrollment to a permanent
        # destination, and then returns to to homelessness. For entries into PH the  re-enrollment must be more
        # than 14 days from the exit date.
        return unless housing_enrollment.exit_date.present? && housing_enrollment.destination.in?([26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]) # From SPM M2

        delayed_project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
        re_enrollments = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          where(client_id: housing_enrollment.client_id, entry_date: (housing_enrollment.exit_date .. filter.end_date))
        returns = re_enrollments.where.not(project_type: delayed_project_types).
          or(re_enrollments.where(project_type: delayed_project_types, entry_date: housing_enrollment.exit_date + 14.days))

        returns.minimum(:entry_date)
      end

      def enrollment_data
        # Source ProjectIDs are used in the report
        project_ids_from_groups = GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids_from_secondary_project_groups).pluck(:project_id)
        universe.members.where(a_t[:project_id].in(project_ids_from_groups)).map(&:universe_membership)
      end
    end
  end
end
