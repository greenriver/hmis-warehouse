# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePool do
  describe '#relevant_form_definition_identifiers' do
    context 'with expressions that refer to CDEs' do
      let!(:fd1) { create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
      # default form definition factory generates cded "fieldOne"
      let!(:cded1) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'fieldOne', form_definition: fd1 }

      let!(:fd2) { create(:custom_assessment_with_custom_fields, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
      # custom_assessment_with_custom_fields factory generates cded "custom_question_1"
      let!(:cded2) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'custom_question_1', form_definition: fd2 }

      let!(:pool) { create :hmis_ce_match_candidate_pool, requirement_expression: "`cde.custom_assessment.fieldOne` = '1'", priority_expression: 'cde.custom_assessment.custom_question_1' }

      it 'returns associated form definition identifiers' do
        expect(pool.relevant_form_definition_identifiers).to contain_exactly(
          fd1.identifier,
          fd2.identifier,
        )
      end
    end
  end
end
