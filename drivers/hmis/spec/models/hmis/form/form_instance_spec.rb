###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.feature 'Hmis Form Instance behavior', type: :model do
  include_context 'hmis base setup'

  let(:role) { 'CUSTOM_ASSESSMENT' }

  let!(:assessment_definition) { create :hmis_form_definition, identifier: 'my_custom_assessment', role: role, data_source: ds1 }
  let!(:old_assessment_definition) { create :hmis_form_definition, identifier: 'my_custom_assessment', status: 'retired', version: 0, role: role, data_source: ds1 }
  let!(:instance1) { create(:hmis_form_instance, role: role, project_type: 2, active: true, definition: assessment_definition) }
  let!(:instance2) { create(:hmis_form_instance, role: role, project_type: 3, active: true, definition: assessment_definition) }

  let(:intake_form) { Hmis::Form::Definition.find_by(role: 'INTAKE') }
  let!(:instance3) { create(:hmis_form_instance, role: 'INTAKE', project_type: 3, active: true, definition: intake_form) }

  describe 'with_role scope' do
    it 'returns rules with the expected scope without duplicates (regression #8617)' do
      scope = Hmis::Form::Instance.with_role(role)
      expect(scope.count).to eq(2)
      expect(scope).to contain_exactly(instance1, instance2)
    end
  end
end
