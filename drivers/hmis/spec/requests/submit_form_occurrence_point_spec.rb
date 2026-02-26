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
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:definition) { create :occurrence_point_form }
  let!(:instance) { create :hmis_form_instance, role: :OCCURRENCE_POINT, entity: p1, active: true, definition: definition }

  let(:move_in_date) { '2024-06-01' }

  let(:mutation) do
    <<~GRAPHQL
      mutation SubmitForm($input: SubmitFormInput!) {
        submitForm(input: $input) {
          record {
            ... on Enrollment {
              id
              moveInDate
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'SubmitForm for OCCURRENCE_POINT' do
    let(:input) do
      {
        form_definition_id: definition.id,
        record_id: e1.id,
        values: { 'date' => move_in_date },
        hud_values: { 'Enrollment.moveInDate' => move_in_date },
      }
    end

    it 'saves the move-in date on the enrollment' do
      response, result = post_graphql(input: { input: input }) { mutation }
      expect(response.status).to eq(200), result.inspect

      record = result.dig('data', 'submitForm', 'record')
      errors = result.dig('data', 'submitForm', 'errors')

      expect(errors).to be_empty
      expect(record).to be_present
      expect(record['id']).to eq(e1.id.to_s)
      expect(record['moveInDate']).to eq(move_in_date)
      expect(e1.reload.move_in_date.strftime('%Y-%m-%d')).to eq(move_in_date)
    end

    context 'when user lacks can_edit_enrollments permission' do
      before { remove_permissions(access_control, :can_edit_enrollments) }

      it 'returns access denied' do
        expect_gql_error post_graphql(input: { input: input }) { mutation }, message: /not authorized/
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
