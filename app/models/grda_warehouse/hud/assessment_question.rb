###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class AssessmentQuestion < Base
    include HudSharedScopes
    include ::HmisStructure::AssessmentQuestion
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :AssessmentQuestions
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    DEFAULT_ANSWERS = {
      '0'	=> 'No',
      '1' => 'Yes',
    }.freeze

    composite_belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessment_questions, optional: true
    composite_belongs_to :assessment, **hud_assoc(:AssessmentID, 'Assessment'), optional: true
    belongs_to :direct_enrollment, **hud_enrollment_belongs, optional: true
    has_one :enrollment, through: :assessment
    has_one :client, through: :assessment, inverse_of: :assessment_questions
    composite_belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), optional: true
    composite_belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :assessment_questions, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], query_constraints: [:EnrollmentID, :PersonalID, :data_source_id], optional: true
    belongs_to :assessment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Assessment', primary_key: [:AssessmentID, :PersonalID, :data_source_id], query_constraints: [:AssessmentID, :PersonalID, :data_source_id], optional: true

    has_one :lookup, class_name: 'GrdaWarehouse::AssessmentAnswerLookup', primary_key: [:AssessmentQuestion, :AssessmentAnswer], query_constraints: [:assessment_question, :response_code]

    scope :pathways_or_rrh, -> do
      where(AssessmentQuestion: :c_housing_assessment_name)

      # Temporary solution until we have the c_housing_assessment_name question in the 2024 pathways assessment
      # where(AssessmentQuestion: [:c_housing_assessment_name, :c_pathways_barriers_yn])
    end

    scope :pathways, -> do
      pathways_or_rrh.
        joins(:lookup).
        merge(GrdaWarehouse::AssessmentAnswerLookup.where(response_text: pathways_titles))
    end

    scope :transfer, -> do
      pathways_or_rrh.
        joins(:lookup).
        merge(GrdaWarehouse::AssessmentAnswerLookup.where(response_text: transfer_titles))
    end

    scope :family_pathways, -> do
      pathways_or_rrh.
        joins(:lookup).
        merge(GrdaWarehouse::AssessmentAnswerLookup.where(response_text: family_pathways_titles))
    end

    # NOTE: you probably want to join/preload :lookup
    def human_readable
      # special case, this is sometimes a 1, but should not be yes so should never use the default responses
      return lookup&.response_text || self.AssessmentAnswer if self.AssessmentQuestion.in?(['c_pathways_Household_size', 'c_larger_room_size'])

      lookup&.response_text || default_response_text(self.AssessmentAnswer) || self.AssessmentAnswer
    end

    def default_response_text(answer)
      DEFAULT_ANSWERS[answer.to_s]
    end

    def pathways?
      self.AssessmentQuestion.to_s == 'c_housing_assessment_name' && human_readable.in?(self.class.pathways_titles)
    end

    def self.pathways_titles
      [
        'Pathways',
        'Pathways 2024',
      ]
    end

    def self.transfer_titles
      [
        'RRH-PSH Transfer',
        'RRH-PSH Transfer 2024',
      ]
    end

    def self.family_pathways_titles
      [
        'Family Pathways 2024',
      ]
    end

    private def pathways_question?
      assessment_question == 'c_housing_assessment_name'
    end

    def assessment_name
      return 'Pathways 2024' if pathways_2024?
      return 'Pathways 2021' if pathways_2021?
      return 'RRH-PSH Transfer' if transfer_2021?
      return 'RRH-PSH Transfer 2024' if transfer_2024?
      return 'Family Pathways 2024' if family_pathways_2024?

      # unknown from assessment questions
      nil
    end

    def family_pathways_2024?
      lookup&.response_text == 'Family Pathways 2024'
    end

    def pathways_2024?
      return nil unless pathways_question?

      lookup&.response_text == 'Pathways 2024'
    end

    def pathways_2021?
      return nil unless pathways_question?

      lookup&.response_text == 'Pathways'
    end

    def transfer_2021?
      return nil unless pathways_question?

      lookup&.response_text == 'RRH-PSH Transfer'
    end

    def transfer_2024?
      return nil unless pathways_question?

      lookup&.response_text == 'RRH-PSH Transfer 2024'
    end
  end
end
