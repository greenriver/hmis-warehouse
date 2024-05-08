###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class AssessmentQuestionsJob < BaseJob
    attr_accessor :form_processor

    # DO NOT CHANGE: Frontend code sends this value
    HIDDEN_FIELD_VALUE = '_HIDDEN'.freeze

    def perform(form_processor_id)
      @form_processor = Hmis::Form::FormProcessor.find(form_processor_id)
      assessment = form_processor.ce_assessment
      return unless assessment.present?

      ::GrdaWarehouse::Hud::AssessmentQuestion.transaction do
        assessment.assessment_questions.delete_all
        questions_to_import = [].tap do |questions|
          form_processor.hud_values.each do |key, value|
            next if key.include?('.') # Field is stored in another HUD object
            next if value == HIDDEN_FIELD_VALUE

            value = case question_type(key)
            when 'BOOLEAN'
              if value
                'Yes'
              else
                'No'
              end
            else
              value
            end

            questions << assessment.assessment_questions.build(
              enrollment_id: assessment.enrollment_id,
              personal_id: assessment.personal_id,
              user_id: assessment.user_id,
              date_created: assessment.assessment_date,
              date_updated: Time.current,

              assessment_question: key,
              # Truncate to ensure value is not too long for db
              assessment_answer: value&.to_s&.truncate(500),
              assessment_question_group: question_group(key),
              assessment_question_order: question_order(key),
            )
          end
        end
        ::GrdaWarehouse::Hud::AssessmentQuestion.import!(questions_to_import)
      end
    end

    private def question_type(key)
      form_definition[key].try(:[], :type)
    end

    private def question_group(key)
      form_definition[key].try(:[], :group)
    end

    private def question_order(key)
      form_definition[key].try(:[], :order)
    end

    def form_definition
      @form_definition ||= {}.tap do |h|
        @order = 1
        definition = form_processor.definition.definition['item']
        h.merge!(parse(definition))
      end
    end

    # Parse form definition hash to determine the order that custom field keys are declared,
    # and when they are nested within a group, the label on the group (otherwise nil)
    #
    # @return Hash of custom_field_keys to a hash containing {group: group_label, order: the order that the fields appear, type: the type declaration}
    private def parse(definition, group: nil)
      {}.tap do |h|
        definition.each do |item|
          type = item['type']
          if type == 'GROUP'
            group = item['text']
            nested_definition = item['item']
            h.merge!(parse(nested_definition, group: group))
          else
            key = item.dig('mapping', 'custom_field_key')
            next unless key.present?

            h[key] = {
              group: group,
              order: @order,
              type: type,
            }
            @order += 1
          end
        end
      end
    end
  end
end
