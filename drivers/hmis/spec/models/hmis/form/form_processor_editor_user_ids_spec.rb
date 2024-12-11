#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::FormProcessor, type: :model do
  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

  let(:definition_json) do
    {
      "item": [
        {
          "type": 'STRING',
          "link_id": 'anyone_can_edit',
          "text": 'Anyone can edit this string field',
          "mapping": {
            "custom_field_key": 'anyone_can_edit',
          },
        },
        {
          "type": 'STRING',
          "link_id": 'only_1_can_edit',
          "text": 'Only 1 user has permission to edit this field',
          "mapping": {
            "custom_field_key": 'only_1_can_edit',
          },
          "editor_user_ids": [hmis_user.id],
        },
      ],
    }
  end
  let!(:definition) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: definition_json }
  let!(:anyone_cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'anyone_can_edit', data_source: ds1, field_type: :string }
  let!(:only_cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'only_1_can_edit', data_source: ds1, field_type: :string }

  context 'when the user does not have permission on an item' do
    let!(:hmis_user_2) { create(:hmis_user, data_source: ds1) }

    it 'skips processing that item but saves all other fields' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'anyone_can_edit' => 'This string will save to the db',
        'only_1_can_edit' => 'This will NOT save',
      }

      expect do
        assessment.form_processor.run!(user: hmis_user_2)
        assessment.save_not_in_progress
      end.to change(Hmis::Hud::CustomDataElement, :count).by(1)

      expect(Hmis::Hud::CustomDataElement.of_type(anyone_cded).sole.value_string).to eq('This string will save to the db')
      expect(Hmis::Hud::CustomDataElement.of_type(only_cded)).to be_empty
    end
  end

  context 'when the user has permission on an item' do
    it 'processes all fields' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: definition, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'anyone_can_edit' => 'This string will save to the db',
        'only_1_can_edit' => 'This will also save',
      }

      expect do
        assessment.form_processor.run!(user: hmis_user)
        assessment.save_not_in_progress
      end.to change(Hmis::Hud::CustomDataElement, :count).by(2)

      expect(Hmis::Hud::CustomDataElement.of_type(anyone_cded).sole.value_string).to eq('This string will save to the db')
      expect(Hmis::Hud::CustomDataElement.of_type(only_cded).sole.value_string).to eq('This will also save')
    end
  end
end
