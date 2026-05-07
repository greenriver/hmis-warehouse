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

RSpec.describe 'SubmitForm for ProjectCoc', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis json forms seed'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let!(:coc) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500', user: u1 }

  let(:definition) { Hmis::Form::Definition.find_by(role: :PROJECT_COC) }
  let(:hud_values) do
    {
      'cocCode' => 'MA-504',
      'geocode' => '250354',
      'geographyType' => 'SUBURBAN',
      'address1' => '1 State Street',
      'address2' => nil,
      'city' => 'Brockton',
      'state' => 'MA',
      'zip' => '12345',
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

  it_behaves_like 'submit form updates HUD User on record'

  it 'creates a new project coc' do
    project_coc = nil
    expect do
      record, = submit_form(input)
      project_coc = Hmis::Hud::ProjectCoc.find(record['id'])
    end.to change(Hmis::Hud::ProjectCoc, :count).by(1)
    expect(project_coc.coc_code).to eq('MA-504')
    expect(project_coc.city).to eq('Brockton')
  end

  it 'persists submitted form values to an existing project coc' do
    expect do
      submit_form(input.merge(record_id: coc.id))
      coc.reload
    end.to change(coc, :coc_code).to('MA-504')
  end

  context 'when user lacks can_edit_project_details permission' do
    before { remove_permissions(access_control, :can_edit_project_details) }

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
