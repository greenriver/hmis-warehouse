###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Scoring::RuleValidator, type: :model do
  let(:definition) do
    create(
      :hmis_form_definition,
      role: :CUSTOM_ASSESSMENT,
      identifier: 'test_form',
      definition: {
        item: [
          {
            type: 'CHOICE',
            link_id: 'question_a',
            text: 'Question A',
            pick_list_options: [{ code: 'Yes' }, { code: 'No' }],
          },
          {
            type: 'CHOICE',
            link_id: 'caregiver',
            text: 'Caregiver',
            pick_list_options: [{ code: 'Yes' }],
            # Written by the form rather than chosen, like the "0" for a household with no minors
            autofill_values: [{ value_code: '0', autofill_when: [{ question: 'question_a', operator: 'EQUAL', answer_code: 'No' }] }],
          },
        ],
      },
    )
  end

  def match_rule(link_id, match_value, **attrs)
    create(
      :hmis_scoring_rule,
      :v2,
      link_id: link_id,
      criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
      criteria_config: { 'match_value' => match_value },
      **attrs,
    )
  end

  def validator(ignored_link_ids: [])
    described_class.new(rules: Hmis::Scoring::Rule.order(:id), definition: definition, ignored_link_ids: ignored_link_ids)
  end

  it 'reports a matched answer the question cannot store, but allows options, blanks, and autofilled values' do
    match_rule('question_a', 'Yes')
    match_rule('question_a', nil)
    match_rule('caregiver', '0')
    bad_rule = match_rule('question_a', 'Maybe')

    issues = validator.issues
    expect(issues.size).to eq(1)
    expect(issues.first.message).to match(/question_a has no answer "Maybe"; it stores "Yes", "No"/)
    expect(issues.first.rule_ids).to eq([bad_rule.id])
  end

  it 'reports missing primary and secondary questions in one run, skipping ignored ones' do
    match_rule('retired_question', 'Yes')
    match_rule(
      'question_a',
      'Yes',
      secondary_link_id: 'new_question',
      secondary_criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
      secondary_criteria_config: { 'match_value' => 'Yes' },
    )
    match_rule('client_demographics_age', 0)

    result = validator(ignored_link_ids: ['client_demographics_age'])
    expect(result.issues.map(&:link_id)).to eq(['new_question', 'retired_question'])
    expect(result.missing_link_ids).to contain_exactly('new_question', 'retired_question')
    expect(result).not_to be_valid
  end
end
