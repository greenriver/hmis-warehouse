# frozen_string_literal: true

module HudReports
  # Shared business logic for HUD household calculations.
  # Extracts pure logic from concerns and builders to ensure consistency across the warehouse.
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

      def calculate_chronic_status(hh_members, current_member, hoh, chronic_status_key: :chronic_status)
        return nil if hh_members.empty?

        # When no specific member is provided (PIT), use the HoH as the current_member
        current_member ||= hoh
        return nil unless current_member

        current_member_entry_date = current_member[:entry_date]
        hoh_entry_date = hoh&.[](:entry_date)
        detail_key = chronic_status_key == :pit_chronic_status ? :pit_chronic_detail : :chronic_detail

        # HoH if they are chronically homeless
        if hoh && hoh[chronic_status_key] && hoh_entry_date == current_member_entry_date
          return { status: true, detail: hoh[detail_key] }
        end

        # If the HoH is not chronically homeless, check if any other adult is
        chronic_adult = hh_members.detect do |hm|
          next false unless hm[:age]

          adult_is_chronic = hm[:age] >= 18 && hm[chronic_status_key]
          adult_matches_entry_date = hm[:entry_date] == hoh_entry_date
          adult_is_chronic && adult_matches_entry_date
        end

        return { status: true, detail: chronic_adult[detail_key] } if chronic_adult

        # if no adults are either yes or no, use self for adults
        if current_member[:age] && current_member[:age] >= 18
          return { status: current_member[chronic_status_key], detail: current_member[detail_key] }
        end

        # if the data is bad and we don't have an HoH, use our own record
        return { status: current_member[chronic_status_key], detail: current_member[detail_key] } if hoh.blank?

        # and the HoH enrollment for children if HoH status is unknown
        if hoh[detail_key].to_s.in?(%w[dk_or_r missing])
          return { status: hoh[chronic_status_key], detail: hoh[detail_key] }
        end

        # if we have an indeterminate response for the child, use the hoh
        if current_member[detail_key].to_s.in?(%w[dk_or_r missing])
          return { status: hoh[chronic_status_key], detail: hoh[detail_key] }
        end

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

      def calculate_is_parenting_youth(member, hh_members)
        age = member[:age]
        adult = age && age >= 18
        (member[:relationship_to_hoh] == 1 || adult) && only_youth?(hh_members) && any_youth_children?(hh_members)
      end

      def only_youth?(hh_members)
        hh_members.all? { |m| m[:age] && m[:age] <= 24 }
      end

      def any_youth_children?(hh_members)
        # Per HUD legacy logic, "children" in the context of youth households include anyone up to age 24
        # if they have RelationshipToHoH == 2.
        hh_members.any? { |m| m[:relationship_to_hoh] == 2 && m[:age] && m[:age] <= 24 }
      end
    end
  end
end
