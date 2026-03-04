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

RSpec.describe 'SubmitForm for NEW_CLIENT_ENROLLMENT', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :NEW_CLIENT_ENROLLMENT) }
  let(:hud_values) do
    {
      'Client.firstName' => 'First',
      'Client.lastName' => 'Last',
      'Client.nameDataQuality' => 'FULL_NAME_REPORTED',
      'Client.dob' => '2000-03-29',
      'Client.dobDataQuality' => 'FULL_DOB_REPORTED',
      'Client.ssn' => 'XXXXX1234',
      'Client.ssnDataQuality' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
      'Client.race' => ['WHITE', 'ASIAN'],
      'Client.gender' => ['WOMAN', 'TRANSGENDER'],
      'Client.veteranStatus' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
      'Enrollment.entryDate' => '2023-09-07',
      'Enrollment.relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
    }.stringify_keys
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      project_id: p1.id,
      confirmed: false,
    }
  end

  it_behaves_like 'submit form triggers IdentifyDuplicates job'

  it 'creates client and enrollment with submitted values' do
    enrollment = nil
    expect do
      record, = submit_form(input)
      enrollment = Hmis::Hud::Enrollment.find(record['id'])
    end.to change(Hmis::Hud::Client, :count).by(1).and change(Hmis::Hud::Enrollment, :count).by(1)

    expect(enrollment.project).to eq(p1)
    expect(enrollment.entry_date).to eq(Date.parse('2023-09-07'))
    expect(enrollment.relationship_to_hoh).to eq(1) # SELF_HEAD_OF_HOUSEHOLD
    expect(enrollment.client.first_name).to eq('First')
    expect(enrollment.client.last_name).to eq('Last')
    expect(enrollment.client.veteran_status).to eq(9) # CLIENT_PREFERS_NOT_TO_ANSWER
  end

  it 'validates client (invalid field)' do
    invalid_input = input.merge(hud_values: hud_values.merge('Client.dobDataQuality' => 'INVALID'))
    expect_validation_error(invalid_input, attribute: 'dobDataQuality', type: 'invalid')
  end

  it 'validates client (invalid DOB)' do
    invalid_input = input.merge(hud_values: hud_values.merge('Client.dob' => '2200-01-01'))
    expect_validation_error(invalid_input, attribute: 'dob', type: 'out_of_range')
  end

  context 'when user cannot create client' do
    before { remove_permissions(access_control, :can_edit_clients) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end

  context 'when user cannot create enrollment' do
    before { remove_permissions(access_control, :can_edit_enrollments) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end

  context 'when trying to submit the form to edit an existing record' do
    let(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }
    it 'raises' do
      expect_raise_error(input.merge(record_id: enrollment.id), message: /cannot be used to edit existing records/)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
