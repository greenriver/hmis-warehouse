###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates one Hmis::Hud::EmploymentEducation record at entry, annual, or exit.
    # Samples field values from valid HUD code sets via HudHelper.util.
    # Subject to record_miss_rate (callers check before invoking).
    #
    # Each field uses an independent Random derived from rng_seed + a fixed offset,
    # so adding new fields in the future does not shift existing field values.
    class EmploymentEducationBuilder < BaseBuilder
      STAGE_CODES = { entry: 1, update: 2, exit: 3, annual: 5 }.freeze

      def initialize(enrollment:, date:, stage:, data_source:, user_id:, rng_seed:)
        super(data_source: data_source, user_id: user_id)
        @enrollment = enrollment
        @date       = date
        @stage      = stage
        @rng_seed   = rng_seed
      end

      def build!
        util = HudHelper.util
        employed = sample_employed

        Hmis::Hud::EmploymentEducation.create!(
          **audit_attrs(@date),
          EmploymentEducationID: FakeIdentifier.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          InformationDate: @date,
          DataCollectionStage: STAGE_CODES.fetch(@stage, 1),
          LastGradeCompleted: sample_from(util.last_grade_completeds, offset: 1),
          SchoolStatus: sample_from(util.school_statuses, offset: 2),
          Employed: employed,
          EmploymentType: (employed == 1 ? sample_from(util.employment_types.reject { |k, _| k == 99 }, offset: 3) : (99 if employed == 99)),
          NotEmployedReason: (employed == 0 ? sample_from(util.not_employed_reasons.reject { |k, _| k == 99 }, offset: 4) : (99 if employed == 99)),
        )
      end

      private

      def sample_from(hash, offset:)
        hash.keys.sample(random: Random.new(@rng_seed + offset))
      end

      def sample_employed
        # Weight toward meaningful responses: 40% employed, 40% not employed, 20% DNC
        weights = { 1 => 0.40, 0 => 0.40, 99 => 0.20 }
        Distribution.sample(
          { 'distribution' => 'weighted', 'weights' => weights.transform_keys(&:to_s) },
          rng: Random.new(@rng_seed),
        ).to_i
      end
    end
  end
end
