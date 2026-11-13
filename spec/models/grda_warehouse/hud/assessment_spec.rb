###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Assessment, type: :model do
  let!(:data_source) { create :source_data_source }

  def add_housing_assessment_name_answer(assessment, response_code:, response_text:)
    GrdaWarehouse::AssessmentAnswerLookup.create!(assessment_question: 'c_housing_assessment_name', response_code: response_code, response_text: response_text)
    create(
      :hud_assessment_question,
      data_source_id: data_source.id,
      AssessmentID: assessment.AssessmentID,
      AssessmentQuestion: 'c_housing_assessment_name',
      AssessmentAnswer: response_code,
    )
  end

  describe '#transfer?' do
    it 'is true when an assessment_question answer is a transfer title' do
      assessment = create(:hud_assessment, data_source_id: data_source.id)
      add_housing_assessment_name_answer(assessment, response_code: 'a', response_text: 'RRH-PSH Transfer')

      expect(assessment.transfer?).to eq(true)
    end

    it 'is false when no assessment_question answer is a transfer title' do
      assessment = create(:hud_assessment, data_source_id: data_source.id)
      create(:hud_assessment_question, data_source_id: data_source.id, AssessmentID: assessment.AssessmentID, AssessmentQuestion: 'some_other_question', AssessmentAnswer: 'whatever')

      expect(assessment.transfer?).to eq(false)
    end
  end

  describe '#pathways_or_transfer?' do
    it 'is true for a pathways assessment' do
      assessment = create(:hud_assessment, data_source_id: data_source.id)
      add_housing_assessment_name_answer(assessment, response_code: 'b', response_text: 'Pathways 2024')

      expect(assessment.pathways_or_transfer?).to eq(true)
    end

    it 'is true for a transfer assessment' do
      assessment = create(:hud_assessment, data_source_id: data_source.id)
      add_housing_assessment_name_answer(assessment, response_code: 'c', response_text: 'RRH Transfer 2024')

      expect(assessment.pathways_or_transfer?).to eq(true)
    end

    it 'is false for an assessment that is neither pathways nor transfer' do
      assessment = create(:hud_assessment, data_source_id: data_source.id)
      create(:hud_assessment_question, data_source_id: data_source.id, AssessmentID: assessment.AssessmentID, AssessmentQuestion: 'some_other_question', AssessmentAnswer: 'whatever')

      expect(assessment.pathways_or_transfer?).to eq(false)
    end
  end

  describe '.pathways_or_transfer' do
    it 'includes pathways and transfer assessments, and excludes other assessments' do
      pathways_assessment = create(:hud_assessment, data_source_id: data_source.id)
      add_housing_assessment_name_answer(pathways_assessment, response_code: 'd', response_text: 'Pathways')

      transfer_assessment = create(:hud_assessment, data_source_id: data_source.id)
      add_housing_assessment_name_answer(transfer_assessment, response_code: 'e', response_text: 'RRH-PSH Transfer 2024')

      other_assessment = create(:hud_assessment, data_source_id: data_source.id)
      create(:hud_assessment_question, data_source_id: data_source.id, AssessmentID: other_assessment.AssessmentID, AssessmentQuestion: 'some_other_question', AssessmentAnswer: 'whatever')

      expect(GrdaWarehouse::Hud::Assessment.pathways_or_transfer).to contain_exactly(pathways_assessment, transfer_assessment)
    end
  end
end
