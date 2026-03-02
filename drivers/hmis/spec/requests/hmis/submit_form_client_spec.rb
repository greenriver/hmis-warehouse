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

RSpec.describe 'SubmitForm for Client', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:c2) { create :hmis_hud_client_complete, data_source: ds1 }

  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :CLIENT) }
  let(:hud_values) do
    {
      'names' => [
        {
          "first": 'First',
          "middle": 'Middle',
          "last": 'Last',
          "suffix": 'Sf',
          "nameDataQuality": 'FULL_NAME_REPORTED',
          "use": nil,
          "notes": nil,
          "primary": true,
        },

      ],
      'dob' => '2000-03-29',
      'dobDataQuality' => 'FULL_DOB_REPORTED',
      'ssn' => 'XXXXX1234',
      'ssnDataQuality' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
      'race' => [
        'WHITE',
        'ASIAN',
      ],
      'gender' => [
        'WOMAN',
        'TRANSGENDER',
      ],
      'pronouns' => [
        'she/her',
      ],
      'veteranStatus' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
      'imageBlobId' => nil,

    }.stringify_keys
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      confirmed: true,
    }
  end

  it 'saves a new client' do
    record, = submit_form(input)
    client = Hmis::Hud::Client.find(record['id'])
    expect(client.first_name).to eq('First')
    expect(client.last_name).to eq('Last')
    expect(client.dob).to eq(Date.parse('2000-03-29'))
    expect(client.ssn).to eq('XXXXX1234')
  end

  it 'persists submitted form values to the existing client' do
    expect do
      submit_form(input.merge(record_id: c2.id))
      c2.reload
    end.to change(c2, :first_name).to('First').and change(c2, :last_name).to('Last')
  end

  context 'when user lacks can_edit_clients permission' do
    before { remove_permissions(access_control, :can_edit_clients) }

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
