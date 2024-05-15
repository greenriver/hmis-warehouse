###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Job for processing CustomAssessments that represent CE Assessments (e.g. HAT) into HUD CE AssessmentQuestions table.
# This is necessary because CAS calculators rely and answers to be present in the AssessmentQuestions table.
module Hmis
  class AssessmentQuestionsJob < BaseJob
    include ::Hmis::Concerns::HmisArelHelper
    attr_accessor :custom_assessment_ids

    def initialize(custom_assessment_ids)
      @custom_assessment_ids = Array.wrap(custom_assessment_ids)
    end

    def perform
      custom_assessment_scope.each do |custom_assessment|
        form_processor = custom_assessment.form_processor
        ce_assessment = form_processor.ce_assessment # AssessmentQuestions will be tied to this HUD CE Assessment
        next unless ce_assessment.present?

        definition = form_definitions_by_id[form_processor.definition_id]
        raise "Form Definition not found: #{form_processor.definition_id}" unless definition

        ::GrdaWarehouse::Hud::AssessmentQuestion.transaction do
          ce_assessment.assessment_questions.delete_all

          questions_to_import = [].tap do |questions|
            question_items = definition.link_id_item_hash.values.select { |item| item.mapping&.custom_field_key.present? }
            question_items.each_with_index do |item, index|
              next unless item.mapping&.custom_field_key

              key = item.mapping.custom_field_key
              cded = custom_data_element_definitions_by_key[key]
              raise "No custom data element definition found for key: #{key}" unless cded

              # find responses to this question
              value = custom_assessment.custom_data_elements.select { |cde| cde.data_element_definition_id == cded.id }&.map(&:value)
              value = nil if value.blank? # [] => nil
              value = value.first if value&.size == 1 # [value] => value
              value = yes_no_nil(value) if cded.field_type.to_sym == :boolean # false => 'No'

              questions << ce_assessment.assessment_questions.build(
                enrollment_id: ce_assessment.enrollment_id,
                personal_id: ce_assessment.personal_id,
                user_id: ce_assessment.user_id,
                date_created: ce_assessment.date_created,
                date_updated: ce_assessment.date_updated,

                # Note: this key is referenced by the tc_hat calculator
                assessment_question: key,
                # Truncate to ensure value is not too long for db
                assessment_answer: value&.to_s&.truncate(500),
                # Name of the section that this question belongs to
                assessment_question_group: definition.link_id_section_hash[item.link_id],
                # Order of this question in the form
                assessment_question_order: index + 1,
              )
            end
          end
          ::GrdaWarehouse::Hud::AssessmentQuestion.import!(questions_to_import)
        end
      end
    end

    private def custom_assessment_scope
      @custom_assessment_scope ||= Hmis::Hud::CustomAssessment.where(id: @custom_assessment_ids).
        joins(:form_processor).
        where(fp_t[:ce_assessment_id].not_eq(nil)).
        preload(form_processor: [:ce_assessment], custom_data_elements: [:data_element_definition])
    end

    def form_definitions_by_id
      @form_definitions_by_id ||= begin
        definition_ids = Hmis::Form::FormProcessor.where(custom_assessment_id: @custom_assessment_ids).pluck(:definition_id).uniq
        Hmis::Form::Definition.where(id: definition_ids).index_by(&:id)
      end
    end

    def custom_data_element_definitions_by_key
      @custom_data_element_definitions_by_key ||= Hmis::Hud::CustomDataElementDefinition.where(owner_type: 'Hmis::Hud::CustomAssessment').index_by(&:key)
    end

    private def yes_no_nil(bool)
      return nil if bool.nil?

      bool ? 'Yes' : 'No'
    end
  end
end
