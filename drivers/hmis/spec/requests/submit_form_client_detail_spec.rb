###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'hmis/login_and_permissions'
require_relative '../support/hmis_base_setup'
require_relative '../support/submit_form_spec_helpers'

RSpec.describe 'SubmitForm for CLIENT_DETAIL', type: :request do
  include_context 'hmis base setup'
  before(:each) do
    hmis_login(user)
  end

  CDE_KEY = 'preferred_contact'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  # Enroll c1 in p1 so the client is viewable by the user
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Client', key: CDE_KEY, field_type: :string, data_source: ds1 }
  let!(:definition) do
    create :hmis_form_definition, role: :CLIENT_DETAIL, definition: {
      'item' => [
        {
          'type' => 'STRING',
          'link_id' => CDE_KEY,
          'text' => 'Preferred Contact Method',
          'mapping' => { 'custom_field_key' => CDE_KEY },
        },
      ],
    }
  end

  let(:input) do
    {
      form_definition_id: definition.id,
      record_id: c1.id,
      values: { CDE_KEY => 'email' },
      hud_values: { CDE_KEY => 'email' },
    }
  end

  it 'saves the custom data element on the client' do
    expect do
      submit_form(input)
      c1.reload
    end.to change(c1.custom_data_elements, :count).by(1).
      and change(cded.values, :count).by(1)

    expect(c1.custom_data_elements.sole.value_string).to eq('email')
    expect(c1.custom_data_elements.sole.data_element_definition).to eq(cded)
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
  c.include SubmitFormSpecHelpers
end
