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
require_relative 'submit_form_spec'

RSpec.describe 'SubmitForm for Organization', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :ORGANIZATION) }
  let(:hud_values) do
    {
      'organizationName' => 'Test org',
      'description' => 'description',
      'contactInformation' => nil,
      'victimServiceProvider' => 'NO',
    }.stringify_keys
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      confirmed: false,
    }
  end

  it_behaves_like 'submit form creates form processor'
  it_behaves_like 'submit form fails when required field is missing'
  it_behaves_like 'submit form fails when form definition is draft'
  it_behaves_like 'submit form updates user correctly'

  it 'creates a new organization' do
    organization = nil
    expect do
      record, = submit_form(input)
      organization = Hmis::Hud::Organization.find(record['id'])
    end.to change(Hmis::Hud::Organization, :count).by(1)

    expect(organization.organization_name).to eq('Test org')
    expect(organization.description).to eq('description')
  end

  it 'persists submitted form values to an existing organization' do
    expect do
      submit_form(input.merge(record_id: o1.id))
      o1.reload
    end.to change(o1, :organization_name).to('Test org')
  end

  context 'when user lacks can_edit_organization permission' do
    before { remove_permissions(access_control, :can_edit_organization) }

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
