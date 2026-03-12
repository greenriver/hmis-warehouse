# frozen_string_literal: true

module HudReports
  # Shared business logic for HUD household calculations.
  #
  # This class centralizes pure logic for household-level attributes required by HUD reports
  # (APR, CAPER, SPM, PIT). It ensures consistency across the warehouse by strictly adhering
  # to the HUD HMIS Reporting Glossary and specific APR/CAPER programming specifications.
  #
  # Key logic areas:
  # - Chronic Status Inheritance: Business rules for how children and households inherit status from adults.
  # - Housing Move-in Inheritance: Rules for cascading move-in dates from the HoH to other members.
  # - Youth/Parenting Youth: Specific APR definitions for youth-led households (often differing from general DQ rules).
  class HouseholdLogic
    class << self
      def calculate_household_type(ages)
        adults = ages.any? { |a| a.present? && a >= 18 }
        children = ages.any? { |a| a.present? && a < 18 }
        any_unknown = ages.any?(&:nil?)

        if adults && children
          :adults_and_children
        elsif any_unknown
          :unknown
        elsif adults
          :adults_only
        elsif children
          :children_only
        else
          :unknown
        end
      end

      # Determines chronic status for a member or PIT snapshot based on household inheritance rules.
      #
      # CH at Project Start (chronic_status): ANY member present at project start can cause other household
      # members to be considered CH — no HoH/adult restriction.
      # CH at Point in Time (pit_chronic_status): at least one adult or minor head of household must be CH.
      # Both modes require the qualifying member to share the HoH's entry date (present at project start).
      def calculate_chronic_status(hh_members, current_member, hoh, chronic_status_key: :chronic_status)
        return nil if hh_members.empty?

        # When no specific member is provided (PIT), use the HoH as the anchor for calculation
        current_member ||= hoh
        return nil unless current_member

        current_member_entry_date = current_member[:entry_date]
        hoh_entry_date = hoh&.[](:entry_date)
        detail_key = chronic_status_key == :pit_chronic_status ? :pit_chronic_detail : :chronic_detail

        if chronic_status_key == :chronic_status
          # CH at Project Start: any member present at start can cause the household to be CH
          chronic_member = hh_members.detect { |hm| hm[chronic_status_key] && hm[:entry_date] == hoh_entry_date }
          return { status: true, detail: chronic_member[detail_key] } if chronic_member
        else
          # CH at Point in Time: check HoH first, then any adult present at start
          return { status: true, detail: hoh[detail_key] } if hoh && hoh[chronic_status_key] && hoh_entry_date == current_member_entry_date

          chronic_adult = hh_members.detect do |hm|
            next false unless hm[:age]

            hm[:age] >= 18 && hm[chronic_status_key] && hm[:entry_date] == hoh_entry_date
          end
          return { status: true, detail: chronic_adult[detail_key] } if chronic_adult
        end

        # Shared fallback: adults use their own status; children inherit from HoH
        return { status: current_member[chronic_status_key], detail: current_member[detail_key] } if current_member[:age] && current_member[:age] >= 18

        # Use self if HoH is missing (data quality issue)
        return { status: current_member[chronic_status_key], detail: current_member[detail_key] } if hoh.blank?

        # Children inherit HoH status if HoH or child has indeterminate (DK/R/Missing) data
        return { status: hoh[chronic_status_key], detail: hoh[detail_key] } if hoh[detail_key].to_s.in?(['dk_or_r', 'missing'])
        return { status: hoh[chronic_status_key], detail: hoh[detail_key] } if current_member[detail_key].to_s.in?(['dk_or_r', 'missing'])

        { status: current_member[chronic_status_key], detail: current_member[detail_key] }
      end

      # [Handling Housing Move-In Dates] - https://files.hudexchange.info/resources/documents/HMIS-Standard-Reporting-Terminology-Glossary-2024.pdf
      def calculate_move_in_date(member, hoh, report_end_date: nil)
        # Rule: Disregard move-in dates outside of enrollment bounds or after report end
        # "Individuals with [housing move-in dates] prior to their [project start dates] or [after]
        # [project exit dates] should have the [housing move-in dates] disregarded entirely."
        valid_move_in = lambda do |date, m|
          date.present? &&
            date >= m[:entry_date] &&
            (m[:exit_date].nil? || date <= m[:exit_date]) &&
            (report_end_date.nil? || date <= report_end_date)
        end

        # 1. If the member has their own valid move-in date, use it
        return member[:move_in_date] if valid_move_in.call(member[:move_in_date], member)

        # 2. Check if HoH has a valid move-in date to propagate
        return nil unless hoh && valid_move_in.call(hoh[:move_in_date], hoh)

        # 3. Inheritance Logic for "Standard" household members (in the household when housed)
        # Rule: "If the household member exited before the household moved into housing,
        # they do not inherit this date."
        if member[:entry_date] <= hoh[:move_in_date]
          # Member was present at time of housing; check if they stayed until the move-in date
          return hoh[:move_in_date] if member[:exit_date].nil? || member[:exit_date] >= hoh[:move_in_date]
        end

        # 4. Inheritance Logic for "Late Joiners"
        # Rule: "If member joins after the household is housed, the member's move-in date = their own project start date"
        if member[:entry_date] > hoh[:move_in_date]
          # Ensure this "inherited" entry date is also valid (not after exit or report end)
          return member[:entry_date] if (member[:exit_date].nil? || member[:entry_date] <= member[:exit_date]) &&
                                       (report_end_date.nil? || member[:entry_date] <= report_end_date)
        end

        nil
      end

      # SPM Measure 1b: Start of homelessness inheritance for children
      def calculate_date_to_street(member, hoh)
        # If member has own DateToStreetESSH, use it (capped at DOB)
        return [member[:date_to_street], member[:dob]].compact.max if member[:date_to_street].present?

        # Inherit from HoH if:
        # 1. Member is age <= 17 (child)
        # 2. Member entered on same date as HoH
        if member[:age].present? &&
           member[:age] <= 17 &&
           member[:entry_date] == hoh&.[](:entry_date)
          date_to_street = hoh&.[](:date_to_street)
          # Cap at DOB if present
          return [date_to_street, member[:dob]].compact.max if date_to_street.present?
        end

        # Otherwise no start of homelessness
        nil
      end

      # APR Q27: Parenting Youth.
      # A youth household (all members 0-24) where the youth (12-24) has children.
      def calculate_is_parenting_youth(member, hh_members)
        age = member[:age]
        adult = age && age >= 18
        (member[:relationship_to_hoh] == 1 || adult) && only_youth?(hh_members) && any_youth_children?(hh_members)
      end

      def only_youth?(hh_members)
        hh_members.all? { |m| m[:age] && m[:age] <= 24 }
      end

      def any_youth_children?(hh_members)
        # Nuance: APR Q27 considers "children" to be anyone with RelationshipToHoH == 2
        # who is age 0-24, provided the entire household qualifies as a Youth Household.
        # This differs from general DQ reports which strictly use age < 18.
        hh_members.any? { |m| m[:relationship_to_hoh] == 2 && m[:age] && m[:age] <= 24 }
      end
    end
  end
end
