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
      # Per HUD Glossary: Status is determined at the earliest project start for the household.
      # If ANY adult or minor HoH is CH, the entire household (and children) are considered CH.
      def calculate_chronic_status(hh_members, current_member, hoh, chronic_status_key: :chronic_status)
        return nil if hh_members.empty?

        # When no specific member is provided (PIT), use the HoH as the anchor for calculation
        current_member ||= hoh
        return nil unless current_member

        current_member_entry_date = current_member[:entry_date]
        hoh_entry_date = hoh&.[](:entry_date)
        detail_key = chronic_status_key == :pit_chronic_status ? :pit_chronic_detail : :chronic_detail

        # Rule: Inheritance from HoH if they are CH and entered together
        return { status: true, detail: hoh[detail_key] } if hoh && hoh[chronic_status_key] && hoh_entry_date == current_member_entry_date

        # Rule: If the HoH is not chronically homeless, check if any other adult is
        chronic_adult = hh_members.detect do |hm|
          next false unless hm[:age]

          adult_is_chronic = hm[:age] >= 18 && hm[chronic_status_key]
          adult_matches_entry_date = hm[:entry_date] == hoh_entry_date
          adult_is_chronic && adult_matches_entry_date
        end

        return { status: true, detail: chronic_adult[detail_key] } if chronic_adult

        # Rule: Adults use their own status if no other adult in the household is CH
        return { status: current_member[chronic_status_key], detail: current_member[detail_key] } if current_member[:age] && current_member[:age] >= 18

        # Fallback: Use self if HoH is missing (data quality issue)
        return { status: current_member[chronic_status_key], detail: current_member[detail_key] } if hoh.blank?

        # Rule: Children inherit HoH status if HoH or Child has indeterminate (DK/R/Missing) data.
        # This ensures children aren't penalized for missing data when an HoH's status might be known or indeterminate.
        return { status: hoh[chronic_status_key], detail: hoh[detail_key] } if hoh[detail_key].to_s.in?(['dk_or_r', 'missing'])

        # Rule: if we have an indeterminate response for the child, use the hoh
        return { status: hoh[chronic_status_key], detail: hoh[detail_key] } if current_member[detail_key].to_s.in?(['dk_or_r', 'missing'])

        { status: current_member[chronic_status_key], detail: current_member[detail_key] }
      end

      # [Handling Housing Move-In Dates] - https://files.hudexchange.info/resources/documents/HMIS-Standard-Reporting-Terminology-Glossary-2024.pdf
      def calculate_move_in_date(member, hoh, report_end_date: nil)
        # If the move-in-date is valid, just use it
        return member[:move_in_date] if member[:move_in_date].present? && member[:move_in_date] >= member[:entry_date]

        # HoH does not exist or does not have a move-in date - cannot do further calculations
        return nil unless hoh && hoh[:move_in_date].present?

        # Heads of household with move-in dates prior to their project start dates should have them disregarded
        return nil unless hoh[:entry_date] <= hoh[:move_in_date]

        # When a household member was already in the household when they became housed
        # For stayers, we use a date far in the future to ensure the move-in date is covered if report_end_date is provided
        exit_date = member[:exit_date] || (report_end_date ? report_end_date + 1.year : nil)

        # If we don't have an exit date and no report end date, we can't safely use .cover? with a Range
        # but the business rule is: "If the household member exited before the household moved into housing,
        # they do not inherit this [housing move-in date]."
        # If exit_date is nil, they are still in the program, so they cover the move-in date if it's >= entry_date.
        if exit_date
          return hoh[:move_in_date] if (member[:entry_date]..exit_date).cover?(hoh[:move_in_date])
        elsif hoh[:move_in_date] >= member[:entry_date]
          return hoh[:move_in_date]
        end

        # When a household member joins the household after they are already housed
        return member[:entry_date] if member[:entry_date] > hoh[:move_in_date]

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
