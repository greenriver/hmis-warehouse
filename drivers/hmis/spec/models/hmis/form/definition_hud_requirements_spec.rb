###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::Definition, type: :model do
  # set rule if unset/changed
  context 'with mock PLS A' do
    let!(:fd) do
      mock_definition = {
        'item': [
          {
            'type': 'DISPLAY',
            'link_id': 'q_3_917A', # HUD link id
            'label': 'fake',
          },
        ],
      }
      fd = create(:hmis_form_definition, definition: mock_definition, role: :INTAKE, identifier: 'test_intake_form')
      fd
    end

    def perform_and_reload
      fd.set_hud_requirements
      fd.save!
      fd.reload
    end

    it 'adds missing rule' do
      perform_and_reload

      expected_rule = HmisUtil::HudAssessmentFormRules2024::HUD_LINK_ID_RULES[:q_3_917A][:rule]
      expect(fd.definition['item'][0]['rule']).to eq(expected_rule.deep_stringify_keys)
    end

    it 'overwrites incorrect rule' do
      fd.definition['item'][0]['rule'] = {
        "operator": 'ANY',
        "parts": [
          {
            "variable": 'projectType',
            "operator": 'EQUAL',
            "value": 14,
          },
        ],
      }
      fd.save!

      perform_and_reload

      expected_rule = HmisUtil::HudAssessmentFormRules2024::HUD_LINK_ID_RULES[:q_3_917A][:rule]
      expect(fd.definition['item'][0]['rule']).to eq(expected_rule.deep_stringify_keys)
    end

    it 'does nothing if role is not required by hud' do
      fd.update!(role: :UPDATE)

      perform_and_reload

      expect(fd.definition['item'][0]['data_collected_about']).to be_nil
      expect(fd.definition['item'][0]['rule']).to be_nil
    end

    # Test against the PLS field which requires 'HOH_AND_ADULTS'
    [
      [nil, 'HOH_AND_ADULTS'],               # Upgrade nil to required level
      ['HOH_AND_ADULTS', 'HOH_AND_ADULTS'],  # Same as required
      ['VETERAN_HOH', 'HOH_AND_ADULTS'],     # Too strict, loosen to required level
      ['ALL_CLIENTS', 'ALL_CLIENTS'],        # Keep as is, since it contains the required level
    ].each do |provided_dca, expected_dca|
      it "sets data_collected_about (#{provided_dca}=>#{expected_dca}) when minimum required is HOH_AND_ADULTS" do
        fd.definition['item'][0]['data_collected_about'] = provided_dca
        fd.save!

        perform_and_reload

        expect(fd.definition['item'][0]['data_collected_about']).to eq(expected_dca)
      end
    end
  end

  # do nothing for different role

  # do nothing for non-hud fields

  # error if hud field is missing from the form
end
