module MaYyaReport
  module GrdaWarehouse
    module HmisFormExtension
      extend ActiveSupport::Concern

      def current_school_attendance
        # First look for the HUD questions
        answers[:sections].each do |s|
          s[:questions].each do |q|
            return HUD.current_school_attended(q[:answer], true) if q[:answer].present? && q[:question] == 'Current school enrollment and attendance'
          end
        end

        # If we didn't find one, try the older format
        answers[:sections].each do |s|
          s[:questions].each do |q|
            response = q[:answer] if q[:answer].present? && q[:question] == 'Level of education'
            return 2 if response.contains?('YYA is currently enrolled in college|') # Assume attending if enrolled
            return 0 if response.contains?('YYA has completed high school or GED/HISET|') # If completed, but not in college, assume not enrolled
          end
        end

        # Finally, give up
        nil
      end

      def most_recent_educational_status
        # First look for the HUD questions
        answers[:sections].each do |s|
          s[:questions].each do |q|
            return HUD.most_recent_ed_status(q[:answer], true) if q[:answer].present? && q[:question] == 'TBD' # FIXME
          end
        end

        # If we didn't find one, try the older format
        answers[:sections].each do |s|
          s[:questions].each do |q|
            response = q[:answer] if q[:answer].present? && q[:question] == 'Level of education'
            return 2 if response.contains?('YYA is currently enrolled in college|') # Assume attending if enrolled
            return 0 if response.contains?('YYA has completed high school or GED/HISET|') # If completed, but not in college, assume not enrolled
          end
        end

        # Finally, give up
        nil
      end

      def current_educational_status
        # First look for the HUD questions
        answers[:sections].each do |s|
          s[:questions].each do |q|
            return HUD.current_ed_status(q[:answer], true) if q[:answer].present? && q[:question] == 'TBD' # FIXME
          end
        end

        # If we didn't find one, try the older format
        answers[:sections].each do |s|
          s[:questions].each do |q|
            response = q[:answer] if q[:answer].present? && q[:question] == 'Level of education'
            return 2 if response.contains?('YYA is currently enrolled in college|') # If they are in college, call it a 4-year
            return nil if response.contains?('YYA has completed high school or GED/HISET|') # reported in most_recent_educational_status
          end
        end

        # Finally, give up
        nil
      end

      def flex_funds
        flex_funds = []
        answers[:sections].each do |s|
          s[:questions].each do |q|
            response = q[:answer] if q[:answer].present? && q[:question] == 'Direct financial assistance provided (check all that apply)'
            next unless response.present?

            parts = response.split('|')
            parts.each do |part|
              part = 'Other' if part.start_with?('Other')
              flex_funds << part
            end
          end
        end
        flex_funds.uniq
      end
    end
  end
end
