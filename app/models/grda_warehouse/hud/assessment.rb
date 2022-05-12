###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Assessment < Base
    include HudSharedScopes
    include ::HMIS::Structure::Assessment
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :Assessment
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessments, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, optional: true
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :assessments, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true
    has_one :client, through: :enrollment, inverse_of: :assessments
    has_many :assessment_questions, **hud_assoc(:AssessmentID, 'AssessmentQuestion')
    has_many :assessment_results, **hud_assoc(:AssessmentID, 'AssessmentResult')

    scope :within_range, ->(range) do
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      where(AssessmentDate: range)
    end

    scope :importable, -> do
      where(synthetic: false)
    end

    scope :synthetic, -> do
      where(synthetic: true)
    end

    scope :pathways_or_rrh, -> do
      where(AssessmentID: GrdaWarehouse::Hud::AssessmentQuestion.pathways_or_rrh.select(:AssessmentID))
    end

    def question_matching_requirement(question, answer = nil)
      matching_question = assessment_questions.
        detect do |q|
          q.AssessmentQuestion.to_s == question
        end
      return nil if matching_question.blank?
      return matching_question unless answer.present?

      matching_question.AssessmentAnswer.to_s == answer
    end

    def results_matching_requirement(question, answer = nil)
      matching_question = assessment_results.
        detect do |q|
          q.AssessmentResultType.to_s == question
        end
      return nil if matching_question.blank?
      return matching_question unless answer.present?

      matching_question.AssessmentResult.to_s == answer
    end
  end
end
