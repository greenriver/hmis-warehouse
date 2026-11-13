###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::AssessmentQuestion, type: :model do
  let!(:data_source) { create :source_data_source }

  describe '#transfer?' do
    it 'is true when the housing assessment name answer is a transfer title' do
      GrdaWarehouse::AssessmentAnswerLookup.create!(assessment_question: 'c_housing_assessment_name', response_code: 'transfer', response_text: 'RRH Transfer 2024')
      question = create(:hud_assessment_question, data_source_id: data_source.id, AssessmentQuestion: 'c_housing_assessment_name', AssessmentAnswer: 'transfer')

      expect(question.transfer?).to eq(true)
    end

    it 'is false when the housing assessment name answer is a pathways title, not a transfer title' do
      GrdaWarehouse::AssessmentAnswerLookup.create!(assessment_question: 'c_housing_assessment_name', response_code: 'pathways', response_text: 'Pathways 2024')
      question = create(:hud_assessment_question, data_source_id: data_source.id, AssessmentQuestion: 'c_housing_assessment_name', AssessmentAnswer: 'pathways')

      expect(question.transfer?).to eq(false)
    end

    it 'is false when the question is not c_housing_assessment_name, even with a transfer-title answer' do
      GrdaWarehouse::AssessmentAnswerLookup.create!(assessment_question: 'some_other_question', response_code: 'transfer', response_text: 'RRH Transfer 2024')
      question = create(:hud_assessment_question, data_source_id: data_source.id, AssessmentQuestion: 'some_other_question', AssessmentAnswer: 'transfer')

      expect(question.transfer?).to eq(false)
    end
  end
end
