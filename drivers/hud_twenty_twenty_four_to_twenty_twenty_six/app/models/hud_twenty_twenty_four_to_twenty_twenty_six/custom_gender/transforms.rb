###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../concerns/hud_twenty_twenty_four_to_twenty_twenty_six/references'

module HudTwentyTwentyFourToTwentyTwentySix
  module CustomGender
    class Transforms
      include HudTwentyTwentyFourToTwentyTwentySix::References

      def self.transforms(csv: false, db: false, references: {}) # rubocop:disable Lint/UnusedMethodArgument, Naming/MethodParameterName
        [
          [HudTwentyTwentyFourToTwentyTwentySix::CustomGender::CreateCustomGender, references],
        ]
      end

      def self.target_class
        HmisCsvTwentyTwentySix::Importer::Custom::CustomGender
      end
    end
  end
end
