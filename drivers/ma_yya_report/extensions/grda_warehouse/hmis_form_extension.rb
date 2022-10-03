module MaYyaReport
  module GrdaWarehouse
    module HmisFormExtension
      extend ActiveSupport::Concern

      def current_school_attendance
        # First look for the HUD questions
        hud_answer = answer_from_section(section_starts_with('First Page'), 'Current school enrollment')
        return HUD.most_recent_ed_status(hud_answer, true) if hud_answer.present?

        # If we didn't find one, try the older format
        legacy_answers = answer_from_section(section_starts_with('First Page'), 'Level of education')
        return 2 if legacy_answers&.contains?('YYA is currently enrolled in college|') # Assume attending if enrolled
        return 0 if legacy_answers&.contains?('YYA has completed high school or GED/HISET|') # If completed, but not in college, assume not enrolled

        # Finally, give up
        nil
      end

      def most_recent_educational_status
        # First look for the HUD questions
        hud_answer = answer_from_section(section_starts_with('First Page'), 'C3.A')
        return HUD.most_recent_ed_status(hud_answer, true) if hud_answer.present?

        # If we didn't find one, try the older format
        legacy_answers = answer_from_section(section_starts_with('First Page'), 'Level of education')
        return 2 if legacy_answers&.contains?('YYA is currently enrolled in college|') # Assume attending if enrolled
        return 0 if legacy_answers&.contains?('YYA has completed high school or GED/HISET|') # If completed, but not in college, assume not enrolled

        # Finally, give up
        nil
      end

      def current_educational_status
        # First look for the HUD questions
        hud_answer = answer_from_section(section_starts_with('First Page'), 'C3.B')
        return HUD.most_recent_ed_status(hud_answer, true) if hud_answer.present?

        # If we didn't find one, try the older format
        legacy_answers = answer_from_section(section_starts_with('First Page'), 'Level of education')
        return 2 if legacy_answers&.contains?('YYA is currently enrolled in college|') # If they are in college, call it a 4-year
        return nil if legacy_answers&.contains?('YYA has completed high school or GED/HISET|') # reported in most_recent_educational_status

        # Finally, give up
        nil
      end

      def flex_funds
        flex_funds = []
        answers = answer_from_section(section_starts_with('First Page'), 'Direct financial assistance')
        if answers.present?
          answers.split('|').each do |part|
            part = 'Move-in' if part.start_with?('Move-in')
            part = 'Other' if part.start_with?('Other')
            flex_funds << part
          end
        end
        flex_funds.uniq
      end
    end
  end
end
