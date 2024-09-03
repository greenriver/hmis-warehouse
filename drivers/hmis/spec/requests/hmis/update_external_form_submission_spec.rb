###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Update External Form Submission', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation UpdateExternalFormSubmission(
        $id: ID!
        $projectId: ID!
        $input: ExternalFormSubmissionInput!
      ) {
        updateExternalFormSubmission(id: $id, projectId: $projectId, input: $input) {
          externalFormSubmission {
            id
            submittedAt
            spam
            status
            notes
            definition {
              identifier
            }
            values
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) do
    create_access_control(hmis_user, p1, with_permission: [:can_manage_external_form_submissions, :can_view_project])
  end

  before(:each) do
    hmis_login(user)
  end

  context 'when reviewing a submission' do
    let!(:definition) { create(:hmis_external_form_definition) }
    let!(:submission) { create(:hmis_external_form_submission, definition: definition, submitted_at: Date.current) }
    let!(:cded) { create(:hmis_custom_data_element_definition, owner_type: submission.class.sti_name, key: 'your_name', data_source: ds1, user: u1) }

    it 'should create CDE' do
      expect do
        input = {
          id: submission.id,
          project_id: p1.id,
          input: {
            status: 'reviewed',
            hud_values: submission.raw_data,
          },
        }

        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result
        expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
      end.to change(Hmis::Hud::CustomDataElement, :count).by(1).
        and not_change(Hmis::Hud::Enrollment, :count).
        and not_change(Hmis::Hud::Client, :count)
    end

    context 'when the submission has client record info' do
      let!(:definition) do
        items = [
          {
            'type': 'STRING',
            'link_id': 'first_name',
            'mapping': {
              'field_name': 'firstName',
              'record_type': 'CLIENT',
            },
            'text': 'First name',
          },
          {
            'type': 'CHOICE',
            'pick_list_reference': 'RelationshipToHoH',
            'link_id': 'relationship_to_hoh',
            'mapping': {
              'field_name': 'relationshipToHoH',
              'record_type': 'ENROLLMENT',
            },
            'text': 'Relationship to HoH',
          },
        ]
        create(:hmis_external_form_definition, append_items: items)
      end
      let!(:submission) do
        data = {
          'first_name': 'Oranges',
          'relationship_to_hoh': 'SELF_HEAD_OF_HOUSEHOLD',
        }
        create(:hmis_external_form_submission, raw_data: data, cleaned_values: data, definition: definition, submitted_at: Date.current)
      end

      it 'should create client' do
        expect do
          input = {
            id: submission.id,
            project_id: p1.id,
            input: {
              status: 'reviewed',
              hud_values: {
                'Client.firstName': 'Oranges',
                'Enrollment.relationshipToHoH': 'SELF_HEAD_OF_HOUSEHOLD',
              }.stringify_keys,
            },
          }

          response, result = post_graphql(input) { mutation }
          expect(response.status).to eq(200), result
          expect(result.dig('data', 'updateExternalFormSubmission', 'externalFormSubmission', 'status')).to eq('reviewed')
        end.to change(Hmis::Hud::Client, :count).by(1).
          and change(Hmis::Hud::Enrollment, :count).by(1)
      end
    end
  end
end
