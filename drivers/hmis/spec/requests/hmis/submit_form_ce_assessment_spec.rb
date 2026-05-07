# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'
require_relative '../../support/shared_examples/submit_form'

RSpec.describe 'SubmitForm for CeAssessment', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis json forms seed'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }
  let!(:a1) { create :hmis_hud_assessment, data_source: ds1, client: c1, enrollment: e1, user: u1 }

  let(:definition) { Hmis::Form::Definition.find_by(role: :CE_ASSESSMENT) }
  let(:hud_values) do
    {
      'assessmentDate' => '2023-08-15',
      'assessmentLocation' => 'test',
      'assessmentType' => 'PHONE',
      'assessmentLevel' => 'CRISIS_NEEDS_ASSESSMENT',
      'prioritizationStatus' => 'PLACED_ON_PRIORITIZATION_LIST',
    }
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      enrollment_id: e1.id,
      confirmed: true,
    }
  end

  it_behaves_like 'submit form updates HUD User on record'

  it 'saves a new ce assessment' do
    record, = submit_form(input)
    assessment = Hmis::Hud::Assessment.find(record['id'])
    expect(assessment.assessment_date).to eq(Date.parse('2023-08-15'))
    expect(assessment.assessment_location).to eq('test')
    expect(assessment.assessment_type).to eq(1) # Phone
    expect(assessment.assessment_level).to eq(1) # Crisis Needs Assessment
    expect(assessment.prioritization_status).to eq(1) # Placed on prioritization list
  end

  it 'persists submitted form values to an existing ce assessment' do
    expect do
      submit_form(input.merge(record_id: a1.id))
      a1.reload
    end.to change(a1, :assessment_date).to(Date.parse('2023-08-15'))
  end

  context 'when user lacks can_edit_enrollments permission' do
    before { remove_permissions(access_control, :can_edit_enrollments) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
