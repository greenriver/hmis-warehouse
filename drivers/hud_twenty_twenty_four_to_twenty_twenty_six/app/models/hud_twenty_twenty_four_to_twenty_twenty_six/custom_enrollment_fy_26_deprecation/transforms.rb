###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../concerns/hud_twenty_twenty_four_to_twenty_twenty_six/references'

module HudTwentyTwentyFourToTwentyTwentySix
  module CustomEnrollmentFy26Deprecation
    class Transforms
      include HudTwentyTwentyFourToTwentyTwentySix::References

      def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
        [
          [HudTwentyTwentyFourToTwentyTwentySix::CustomEnrollmentFy26Deprecation::CreateCustomEnrollmentFy26Deprecation, references],
        ]
      end

      def self.target_class
        HmisCsvTwentyTwentySix::Importer::Custom::CustomEnrollmentFy26Deprecation
      end
    end
  end
end
