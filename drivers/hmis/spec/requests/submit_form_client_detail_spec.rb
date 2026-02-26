###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'hmis/login_and_permissions'
require_relative '../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  # Enroll c1 in p1 so the client is viewable by the user
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Client', key: 'preferred_contact', field_type: :string, data_source: ds1 }
  let!(:definition) do
    create :hmis_form_definition, role: :CLIENT_DETAIL, definition: {
      'item' => [
        {
          'type' => 'STRING',
          'link_id' => 'preferred_contact',
          'text' => 'Preferred Contact Method',
          'mapping' => { 'custom_field_key' => 'preferred_contact' },
        },
      ],
    }
  end
  # CLIENT_DETAIL form instances have no entity (global)
  let!(:instance) { create :hmis_form_instance, definition: definition, entity: nil, active: true }

  let(:mutation) do
    <<~GRAPHQL
      mutation SubmitForm($input: SubmitFormInput!) {
        submitForm(input: $input) {
          record {
            ... on Client {
              id
            }
          }
          errors {
            type
            attribute
            message
          }
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'SubmitForm for CLIENT_DETAIL' do
    let(:input) do
      {
        form_definition_id: definition.id,
        record_id: c1.id,
        values: { 'preferred_contact' => 'email' },
        hud_values: { 'preferred_contact' => 'email' },
      }
    end

    it 'saves the custom data element on the client' do
      response, result = post_graphql(input: { input: input }) { mutation }
      expect(response.status).to eq(200), result.inspect

      record = result.dig('data', 'submitForm', 'record')
      errors = result.dig('data', 'submitForm', 'errors')

      expect(errors).to be_empty
      expect(record).to be_present
      expect(record['id']).to eq(c1.id.to_s)

      cde = c1.reload.custom_data_elements.find_by(data_element_definition: cded)
      expect(cde).to be_present
      expect(cde.value_string).to eq('email')
    end

    context 'when user lacks can_edit_clients permission' do
      before { remove_permissions(access_control, :can_edit_clients) }

      it 'returns access denied' do
        expect_gql_error post_graphql(input: { input: input }) { mutation }, message: /not authorized/
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
