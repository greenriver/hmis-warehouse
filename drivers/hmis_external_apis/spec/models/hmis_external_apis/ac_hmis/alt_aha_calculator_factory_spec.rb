###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::AltAhaCalculatorFactory, type: :model do
  let(:owner) { create(:hmis_hud_enrollment) }
  let(:user) { create(:hmis_user) }
  let(:client) { create(:hmis_hud_client) }
  let(:definition) do
    create(
      :hmis_form_definition,
      role: :CUSTOM_ASSESSMENT,
      identifier: 'test_form',
      definition: {
        item: [
          { type: 'DATE', link_id: 'assessment_date', text: 'Assessment Date', assessment_date: true },
          { type: 'STRING', link_id: 'question_a', text: 'Question A' },
          { type: 'STRING', link_id: 'question_b', text: 'Question B' },
        ],
      },
    )
  end

  def build
    described_class.build(definition: definition, values_by_link_id: {}, client: client, user: user, owner: owner)
  end

  def set_model_version(value_input)
    AppConfigProperty.create!(key: 'ac_hmis/alt_aha_model_version', value_input: value_input)
  end

  describe 'choosing the calculator' do
    it 'builds the version 1 calculator when the property is unset' do
      expect(build).to be_a(HmisExternalApis::AcHmis::AltAhaCalculator)
    end

    it 'builds the version 2 calculator when the property is 2' do
      set_model_version('2')
      expect(build).to be_a(HmisExternalApis::AcHmis::AltAhaV2Calculator)
    end
  end

  describe 'checking rules against the definition' do
    it 'allows rules whose questions are on the definition, plus client demographics' do
      create(:hmis_scoring_rule, :v1, link_id: 'question_a', algorithm: 'alt_aha_1')
      create(:hmis_scoring_rule, :v1, link_id: 'client_demographics_age', algorithm: 'alt_aha_1')
      create(:hmis_scoring_rule, :v1, link_id: 'client_demographics_gender', algorithm: 'alt_aha_1')

      expect { build }.not_to raise_error
    end

    it 'raises for a version 1 rule whose question is not on the definition' do
      create(:hmis_scoring_rule, :v1, link_id: 'retired_question', algorithm: 'alt_aha_1')

      expect { build }.to raise_error(/model version 1 .* not on form definition #{definition.id}: retired_question/)
    end

    context 'when the property is 2' do
      before { set_model_version('2') }

      it 'raises for a version 2 rule whose question is not on the definition' do
        create(:hmis_scoring_rule, :v2, link_id: 'new_question', algorithm: 'alt_aha_1')

        expect { build }.to raise_error(/model version 2 .*: new_question/)
      end

      it 'raises for a version 2 rule whose secondary question is not on the definition' do
        create(
          :hmis_scoring_rule,
          :v2,
          link_id: 'question_a',
          criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
          criteria_config: { 'match_value' => 'Yes' },
          secondary_link_id: 'new_question',
          secondary_criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
          secondary_criteria_config: { 'match_value' => 'Yes' },
          algorithm: 'alt_aha_1',
        )

        expect { build }.to raise_error(/model version 2 .*: new_question/)
      end

      it 'ignores version 1 rules' do
        create(:hmis_scoring_rule, :v1, link_id: 'retired_question', algorithm: 'alt_aha_1')

        expect { build }.not_to raise_error
      end
    end

    it 'ignores rules for other forms' do
      create(:hmis_scoring_rule, :v1, link_id: 'retired_question', form_definition_identifier: 'other_form', algorithm: 'alt_aha_1')

      expect { build }.not_to raise_error
    end
  end
end
