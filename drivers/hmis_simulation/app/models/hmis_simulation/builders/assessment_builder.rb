###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates one Hmis::Hud::Assessment + 3-5 Hmis::Hud::AssessmentResult records
    # for a CE enrollment. AssessmentQuestions are not generated.
    #
    # Scores are plausible-looking numeric strings drawn from a fixed list of
    # result type / value generators (e.g. "VI-SPDAT Score" → 0-17).
    class AssessmentBuilder < BaseBuilder
      # Each entry: [result_type_label, value_range]
      RESULT_TYPES = [
        ['VI-SPDAT Score',        0..17],
        ['Vulnerability Score',   0..100],
        ['Chronic Homelessness',  0..1],
        ['Days Homeless (Est.)',  0..730],
        ['Crisis Needs Score',    0..20],
      ].freeze

      def initialize(enrollment:, date:, data_source:, user_id:, rng_seed:, id_generator: FakeIdentifier)
        super(data_source: data_source, user_id: user_id, id_generator: id_generator)
        @enrollment = enrollment
        @date       = date
        @rng        = Random.new(rng_seed)
      end

      def build!
        assessment = Hmis::Hud::Assessment.create!(
          **audit_attrs(@date),
          AssessmentID: @id_gen.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          AssessmentDate: @date,
          AssessmentLocation: 'Community Assessment Site',
          AssessmentType: @rng.rand(1..3),
          AssessmentLevel: @rng.rand(1..2),
          PrioritizationStatus: @rng.rand(1..2),
        )

        result_count = [3 + @rng.rand(3), RESULT_TYPES.size].min
        RESULT_TYPES.sample(result_count, random: @rng).each do |type_label, value_range|
          Hmis::Hud::AssessmentResult.create!(
            **audit_attrs(@date),
            AssessmentResultID: @id_gen.uuid,
            AssessmentID: assessment.AssessmentID,
            EnrollmentID: @enrollment.EnrollmentID,
            PersonalID: @enrollment.PersonalID,
            AssessmentResultType: type_label,
            AssessmentResult: @rng.rand(value_range).to_s,
          )
        end

        assessment
      end
    end
  end
end
